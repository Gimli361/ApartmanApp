using ApartmanApp.Business.DTOs.Aidat;
using ApartmanApp.Business.Services.Concrete;
using ApartmanApp.Core.Entities;
using ApartmanApp.Core.Enums;
using ApartmanApp.Tests.TestHelpers;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Tests.Services;

public class AidatServiceTests
{
    private static Kullanici Sakin(int id = 1, string daire = "1") => new()
    {
        Id = id,
        Ad = "Test",
        Soyad = "User",
        Email = $"sakin{id}@test.com",
        DaireNo = daire,
        Rol = KullaniciRol.Sakin,
        SifreHash = "x"
    };

    [Fact]
    public async Task CreateAsync_AyniDonemeIkinciKayit_FailDoner()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(Sakin());
        await db.SaveChangesAsync();

        var service = new AidatService(db, TestDb.CreateMapper());

        var first = await service.CreateAsync(new AidatCreateDto
        {
            KullaniciId = 1,
            Tutar = 500,
            Ay = 6,
            Yil = 2026
        });
        first.Success.Should().BeTrue();

        var duplicate = await service.CreateAsync(new AidatCreateDto
        {
            KullaniciId = 1,
            Tutar = 500,
            Ay = 6,
            Yil = 2026
        });
        duplicate.Success.Should().BeFalse();
    }

    [Fact]
    public async Task CreateAsync_OlmayanKullanici_FailDoner()
    {
        await using var db = TestDb.CreateDbContext();
        var service = new AidatService(db, TestDb.CreateMapper());

        var result = await service.CreateAsync(new AidatCreateDto
        {
            KullaniciId = 999,
            Tutar = 500,
            Ay = 6,
            Yil = 2026
        });

        result.Success.Should().BeFalse();
    }

    [Fact]
    public async Task DeleteAsync_SoftDeleteUygular_QueryFilterGizler()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(Sakin());
        await db.SaveChangesAsync();

        var service = new AidatService(db, TestDb.CreateMapper());
        var created = await service.CreateAsync(new AidatCreateDto
        {
            KullaniciId = 1, Tutar = 500, Ay = 6, Yil = 2026
        });
        var aidatId = created.Data!.Id;

        // Soft delete
        var del = await service.DeleteAsync(aidatId);
        del.Success.Should().BeTrue();

        // Default sorgu silinen kaydı görmemeli
        var afterDelete = await service.GetByIdAsync(aidatId);
        afterDelete.Success.Should().BeFalse();

        // Ama row hâlâ DB'de — IgnoreQueryFilters ile çekilebilir
        var rawCount = await db.Aidatlar.IgnoreQueryFilters().CountAsync();
        rawCount.Should().Be(1);

        var soft = await db.Aidatlar.IgnoreQueryFilters().FirstAsync();
        soft.IsDeleted.Should().BeTrue();
        soft.DeletedAt.Should().NotBeNull();
    }

    [Fact]
    public async Task UpdateOdemeDurumAsync_OdendiSecince_OdemeTarihiSetEdilir()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(Sakin());
        await db.SaveChangesAsync();

        var service = new AidatService(db, TestDb.CreateMapper());
        var created = await service.CreateAsync(new AidatCreateDto
        {
            KullaniciId = 1, Tutar = 500, Ay = 6, Yil = 2026
        });

        var updated = await service.UpdateOdemeDurumAsync(
            created.Data!.Id,
            new AidatOdemeDurumGuncelleDto { OdemeDurumu = OdemeDurumu.Odendi });

        updated.Success.Should().BeTrue();
        var entity = await db.Aidatlar.FirstAsync();
        entity.OdemeTarihi.Should().NotBeNull();
        entity.OdemeDurumu.Should().Be(OdemeDurumu.Odendi);
    }
}
