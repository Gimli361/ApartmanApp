using ApartmanApp.Business.DTOs.Oylama;
using ApartmanApp.Business.Services.Concrete;
using ApartmanApp.Core.Entities;
using ApartmanApp.Core.Enums;
using ApartmanApp.Tests.TestHelpers;
using FluentAssertions;

namespace ApartmanApp.Tests.Services;

public class OylamaServiceTests
{
    private static Kullanici Sakin(int id) => new()
    {
        Id = id,
        Ad = "K",
        Soyad = id.ToString(),
        Email = $"k{id}@test.com",
        DaireNo = id.ToString(),
        Rol = KullaniciRol.Sakin,
        SifreHash = "x"
    };

    [Fact]
    public async Task CreateAsync_GecerliVeri_OylamaVeSeceneklerOlusur()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(Sakin(1));
        await db.SaveChangesAsync();

        var service = new OylamaService(db);

        var result = await service.CreateAsync(new OylamaCreateDto
        {
            Baslik = "Test",
            BitisTarihi = DateTime.UtcNow.AddDays(7),
            Secenekler = new List<string> { "Evet", "Hayir" }
        }, olusturanId: 1);

        result.Success.Should().BeTrue();
        result.Data!.Secenekler.Count.Should().Be(2);
    }

    [Fact]
    public async Task OyVerAsync_AyniKullaniciIkinciKezDener_FailDoner()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(Sakin(1));
        await db.SaveChangesAsync();

        var service = new OylamaService(db);
        var oylama = await service.CreateAsync(new OylamaCreateDto
        {
            Baslik = "T",
            BitisTarihi = DateTime.UtcNow.AddDays(7),
            Secenekler = new List<string> { "A", "B" }
        }, olusturanId: 1);

        var sec1 = oylama.Data!.Secenekler[0].Id;
        var sec2 = oylama.Data.Secenekler[1].Id;

        var ilk = await service.OyVerAsync(oylama.Data.Id, sec1, kullaniciId: 1);
        ilk.Success.Should().BeTrue();

        var ikinci = await service.OyVerAsync(oylama.Data.Id, sec2, kullaniciId: 1);
        ikinci.Success.Should().BeFalse();

        // Sadece tek oy DB'de
        var oylar = db.OylamaOylari
            .Where(o => o.OylamaId == oylama.Data.Id && o.KullaniciId == 1)
            .ToList();
        oylar.Should().HaveCount(1);
        oylar[0].SecenekId.Should().Be(sec1);
    }

    [Fact]
    public async Task OyGeriAlAsync_OyKaldirir()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(Sakin(1));
        await db.SaveChangesAsync();

        var service = new OylamaService(db);
        var oylama = await service.CreateAsync(new OylamaCreateDto
        {
            Baslik = "T",
            BitisTarihi = DateTime.UtcNow.AddDays(7),
            Secenekler = new List<string> { "A", "B" }
        }, olusturanId: 1);

        var sec1 = oylama.Data!.Secenekler[0].Id;
        await service.OyVerAsync(oylama.Data.Id, sec1, kullaniciId: 1);

        var geriAl = await service.OyGeriAlAsync(oylama.Data.Id, kullaniciId: 1);
        geriAl.Success.Should().BeTrue();

        // Geri aldıktan sonra tekrar oy verebilmeli
        var tekrar = await service.OyVerAsync(oylama.Data.Id, sec1, kullaniciId: 1);
        tekrar.Success.Should().BeTrue();
    }

    [Fact]
    public async Task OyVerAsync_PasifOylama_FailDoner()
    {
        await using var db = TestDb.CreateDbContext();
        db.Kullanicilar.Add(Sakin(1));
        await db.SaveChangesAsync();

        var service = new OylamaService(db);
        var created = await service.CreateAsync(new OylamaCreateDto
        {
            Baslik = "T",
            BitisTarihi = DateTime.UtcNow.AddDays(7),
            Secenekler = new List<string> { "A", "B" }
        }, olusturanId: 1);

        await service.ToggleAktifAsync(created.Data!.Id);

        var sec1 = created.Data.Secenekler[0].Id;
        var result = await service.OyVerAsync(created.Data.Id, sec1, kullaniciId: 1);

        result.Success.Should().BeFalse();
    }
}
