using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using ApartmanApp.Business.DTOs.Auth;
using ApartmanApp.Business.DTOs.Kullanici;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Data.Context;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace ApartmanApp.Business.Services.Concrete;

public class AuthService(AppDbContext db, IMapper mapper, IConfiguration config) : IAuthService
{
    public async Task<Result<TokenResponseDto>> LoginAsync(LoginDto dto)
    {
        var kullanici = await db.Kullanicilar
            .AsNoTracking()
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

        var token = GenerateToken(kullanici.Id, kullanici.Email, kullanici.Rol.ToString());
        var expiryMinutes = config.GetValue<int>("Jwt:ExpiryMinutes", 1440);

        var response = new TokenResponseDto
        {
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes),
            User = mapper.Map<KullaniciListDto>(kullanici)
        };

        return Result<TokenResponseDto>.Ok(response, "Giriş başarılı.");
    }

    private string GenerateToken(int userId, string email, string rol)
    {
        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(config["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expiryMinutes = config.GetValue<int>("Jwt:ExpiryMinutes", 1440);

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
