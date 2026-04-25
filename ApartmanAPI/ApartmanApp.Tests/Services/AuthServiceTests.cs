using ApartmanApp.Business.DTOs.Auth;
using ApartmanApp.Business.Services.Concrete;
using ApartmanApp.Core.Entities;
using ApartmanApp.Core.Enums;
using ApartmanApp.Tests.TestHelpers;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Tests.Services;

public class AuthServiceTests
{
    private static Kullanici CreateUser(string email = "test@apartman.com", string password = "Test123!")
    {
        return new Kullanici
        {
            Ad = "Test",
            Soyad = "User",
            Email = email,
            DaireNo = "1",
            Rol = KullaniciRol.Sakin,
            SifreHash = BCrypt.Net.BCrypt.HashPassword(password),
        };
    }

    [Fact]
    public async Task LoginAsync_DogruSifre_AccessVeRefreshTokenDoner()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(CreateUser());
        await db.SaveChangesAsync();

        var service = new AuthService(db, TestDb.CreateMapper(), TestDb.CreateConfig());

        var result = await service.LoginAsync(new LoginDto
        {
            Email = "test@apartman.com",
            Sifre = "Test123!"
        });

        result.Success.Should().BeTrue();
        result.Data!.Token.Should().NotBeNullOrWhiteSpace();
        result.Data.RefreshToken.Should().NotBeNullOrWhiteSpace();
        (await db.RefreshTokens.CountAsync()).Should().Be(1);
    }

    [Fact]
    public async Task LoginAsync_YanlisSifre_BasarisizDoner()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(CreateUser());
        await db.SaveChangesAsync();

        var service = new AuthService(db, TestDb.CreateMapper(), TestDb.CreateConfig());

        var result = await service.LoginAsync(new LoginDto
        {
            Email = "test@apartman.com",
            Sifre = "Yanlis999!"
        });

        result.Success.Should().BeFalse();
    }

    [Fact]
    public async Task LoginAsync_OlmayanKullanici_BasarisizDoner()
    {
        await using var db = TestDb.CreateDbContext();
        var service = new AuthService(db, TestDb.CreateMapper(), TestDb.CreateConfig());

        var result = await service.LoginAsync(new LoginDto
        {
            Email = "yok@apartman.com",
            Sifre = "Test123!"
        });

        result.Success.Should().BeFalse();
    }

    [Fact]
    public async Task RefreshAsync_GecerliToken_RotationYaparVeYeniPairUretir()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(CreateUser());
        await db.SaveChangesAsync();

        var service = new AuthService(db, TestDb.CreateMapper(), TestDb.CreateConfig());
        var login = await service.LoginAsync(new LoginDto
        {
            Email = "test@apartman.com",
            Sifre = "Test123!"
        });
        var oldRefresh = login.Data!.RefreshToken;

        var refreshed = await service.RefreshAsync(oldRefresh);

        refreshed.Success.Should().BeTrue();
        refreshed.Data!.RefreshToken.Should().NotBe(oldRefresh);

        // Eski token revoke edilmiş ve yeni ile zincirlenmiş olmalı
        var oldEntity = await db.RefreshTokens
            .FirstAsync(rt => rt.Token == oldRefresh);
        oldEntity.RevokedAt.Should().NotBeNull();
        oldEntity.ReplacedByToken.Should().Be(refreshed.Data.RefreshToken);
    }

    [Fact]
    public async Task RefreshAsync_RevokeEdilmisToken_TumZinciriRevokeEder()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(CreateUser());
        await db.SaveChangesAsync();

        var service = new AuthService(db, TestDb.CreateMapper(), TestDb.CreateConfig());
        var login = await service.LoginAsync(new LoginDto
        {
            Email = "test@apartman.com",
            Sifre = "Test123!"
        });
        var first = login.Data!.RefreshToken;

        // İlk rotation — first artık revoke
        var refreshed = await service.RefreshAsync(first);
        var second = refreshed.Data!.RefreshToken;

        // Replay: ilk token tekrar gönderiliyor
        var replay = await service.RefreshAsync(first);
        replay.Success.Should().BeFalse();

        // İkinci token da güvenlik için revoke edilmiş olmalı
        var secondEntity = await db.RefreshTokens
            .FirstAsync(rt => rt.Token == second);
        secondEntity.RevokedAt.Should().NotBeNull();
    }

    [Fact]
    public async Task LogoutAsync_TokeniRevokeEder()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(CreateUser());
        await db.SaveChangesAsync();

        var service = new AuthService(db, TestDb.CreateMapper(), TestDb.CreateConfig());
        var login = await service.LoginAsync(new LoginDto
        {
            Email = "test@apartman.com",
            Sifre = "Test123!"
        });

        await service.LogoutAsync(login.Data!.RefreshToken);

        var rt = await db.RefreshTokens.FirstAsync();
        rt.RevokedAt.Should().NotBeNull();

        // Logout sonrası refresh denemesi → 401
        var afterLogout = await service.RefreshAsync(login.Data.RefreshToken);
        afterLogout.Success.Should().BeFalse();
    }
}
