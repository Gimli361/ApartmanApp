using ApartmanApp.Business.DTOs.Ariza;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Data.Context;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Business.Services.Concrete;

public class ArizaTakipService(AppDbContext db) : IArizaTakipService
{
    public async Task<Result> TakipEtAsync(int arizaId, int kullaniciId)
    {
        var arizaVar = await db.Arizalar.AnyAsync(a => a.Id == arizaId);
        if (!arizaVar)
            return Result.Fail("Arıza bulunamadı.");

        var mevcutTakip = await db.ArizaTakipler
            .AnyAsync(t => t.ArizaId == arizaId && t.KullaniciId == kullaniciId);

        if (mevcutTakip)
            return Result.Ok("Bu arıza zaten takip ediliyor.");

        db.ArizaTakipler.Add(new ArizaTakip
        {
            ArizaId = arizaId,
            KullaniciId = kullaniciId,
            TakipTarihi = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        return Result.Ok("Arıza takibe alındı.");
    }

    public async Task<Result> TakiptenCikAsync(int arizaId, int kullaniciId)
    {
        var takip = await db.ArizaTakipler
            .FirstOrDefaultAsync(t => t.ArizaId == arizaId && t.KullaniciId == kullaniciId);

        if (takip is null)
            return Result.Fail("Takip kaydı bulunamadı.");

        db.ArizaTakipler.Remove(takip);
        await db.SaveChangesAsync();

        return Result.Ok("Takipten çıkıldı.");
    }

    public async Task<TakipDurumuDto> GetTakipDurumuAsync(int arizaId, int kullaniciId)
    {
        var takipEdiyor = await db.ArizaTakipler
            .AnyAsync(t => t.ArizaId == arizaId && t.KullaniciId == kullaniciId);

        var takipciSayisi = await db.ArizaTakipler
            .CountAsync(t => t.ArizaId == arizaId);

        return new TakipDurumuDto
        {
            TakipEdiyor = takipEdiyor,
            TakipciSayisi = takipciSayisi,
        };
    }

}
