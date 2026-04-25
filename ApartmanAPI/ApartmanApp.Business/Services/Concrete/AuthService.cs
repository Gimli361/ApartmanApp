using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using ApartmanApp.Business.DTOs.Auth;
using ApartmanApp.Business.DTOs.Kullanici;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Data.Context;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace ApartmanApp.Business.Services.Concrete;

public class AuthService(AppDbContext db, IMapper mapper, IConfiguration config) : IAuthService
{
    private const int RefreshTokenExpiryDays = 30;

    public async Task<Result<TokenResponseDto>> LoginAsync(LoginDto dto)
    {
        var kullanici = await db.Kullanicilar
            .FirstOrDefaultAsync(k => k.Email.ToLower() == dto.Email.ToLower());

        if (kullanici is null)
            return Result<TokenResponseDto>.Fail("Email veya şifre hatalı.");

        bool sifreGecerli;
        try
        {
            sifreGecerli = BCrypt.Net.BCrypt.Verify(dto.Sifre, kullanici.SifreHash);
        }
        catch
        {
            sifreGecerli = false;
        }

        if (!sifreGecerli)
            return Result<TokenResponseDto>.Fail("Email veya şifre hatalı.");

        var response = await IssueTokenPairAsync(kullanici);
        return Result<TokenResponseDto>.Ok(response, "Giriş başarılı.");
    }

    public async Task<Result<TokenResponseDto>> RefreshAsync(string refreshToken)
    {
        if (string.IsNullOrWhiteSpace(refreshToken))
            return Result<TokenResponseDto>.Fail("Refresh token zorunludur.");

        var existing = await db.RefreshTokens
            .Include(rt => rt.Kullanici)
            .FirstOrDefaultAsync(rt => rt.Token == refreshToken);

        if (existing is null)
            return Result<TokenResponseDto>.Fail("Geçersiz refresh token.");

        // Replay saldırı tespiti — daha önce kullanılmış (revoked) bir token tekrar
        // gelirse, bu kullanıcının tüm aktif token'larını revoke et.
        if (existing.RevokedAt is not null)
        {
            await RevokeAllForUserAsync(existing.KullaniciId, "replay-detected");
            return Result<TokenResponseDto>.Fail("Refresh token reddedildi (replay).");
        }

        if (DateTime.UtcNow >= existing.ExpiresAt)
            return Result<TokenResponseDto>.Fail("Refresh token süresi dolmuş.");

        if (existing.Kullanici is null)
            return Result<TokenResponseDto>.Fail("Kullanıcı bulunamadı.");

        // Rotation: eski token revoke + yeni pair üret
        var newPair = await IssueTokenPairAsync(existing.Kullanici);
        existing.RevokedAt = DateTime.UtcNow;
        existing.ReplacedByToken = newPair.RefreshToken;
        await db.SaveChangesAsync();

        return Result<TokenResponseDto>.Ok(newPair, "Token yenilendi.");
    }

    public async Task<Result> LogoutAsync(string refreshToken)
    {
        if (string.IsNullOrWhiteSpace(refreshToken))
            return Result.Ok();

        var existing = await db.RefreshTokens
            .FirstOrDefaultAsync(rt => rt.Token == refreshToken);

        if (existing is not null && existing.RevokedAt is null)
        {
            existing.RevokedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();
        }

        return Result.Ok("Çıkış yapıldı.");
    }

    // ─── Helpers ────────────────────────────────────────────

    private async Task<TokenResponseDto> IssueTokenPairAsync(Kullanici kullanici)
    {
        var accessExpiry = config.GetValue<int>("Jwt:ExpiryMinutes", 60);
        var token = GenerateToken(kullanici.Id, kullanici.Email, kullanici.Rol.ToString(), accessExpiry);

        var refreshToken = new RefreshToken
        {
            Token = GenerateRefreshToken(),
            KullaniciId = kullanici.Id,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddDays(RefreshTokenExpiryDays),
        };
        db.RefreshTokens.Add(refreshToken);
        await db.SaveChangesAsync();

        return new TokenResponseDto
        {
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddMinutes(accessExpiry),
            RefreshToken = refreshToken.Token,
            RefreshTokenExpiresAt = refreshToken.ExpiresAt,
            User = mapper.Map<KullaniciListDto>(kullanici),
        };
    }

    private async Task RevokeAllForUserAsync(int kullaniciId, string reason)
    {
        var aktifler = await db.RefreshTokens
            .Where(rt => rt.KullaniciId == kullaniciId && rt.RevokedAt == null)
            .ToListAsync();
        var now = DateTime.UtcNow;
        foreach (var t in aktifler)
        {
            t.RevokedAt = now;
            t.ReplacedByToken = $"[revoked:{reason}]";
        }
        await db.SaveChangesAsync();
    }

    private static string GenerateRefreshToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);
        return Convert.ToBase64String(bytes)
            .Replace("+", "-").Replace("/", "_").Replace("=", "");
    }

    private string GenerateToken(int userId, string email, string rol, int expiryMinutes)
    {
        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(config["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, email),
            new Claim(ClaimTypes.Role, rol),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        };

        var token = new JwtSecurityToken(
            issuer: config["Jwt:Issuer"],
            audience: config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
