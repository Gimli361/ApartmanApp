using ApartmanApp.Business.DTOs.Aidat;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Core.Enums;
using ApartmanApp.Data.Context;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace ApartmanApp.Business.Services.Concrete;

public class OtomatikAidatService(AppDbContext db, ILogger<OtomatikAidatService> logger)
    : IOtomatikAidatService
{
    public async Task<Result<List<OtomatikAidatDto>>> GetAllAsync()
    {
        var list = await db.OtomatikAidatlar
            .Include(o => o.Kullanici)
            .OrderBy(o => o.Kullanici.DaireNo)
            .AsNoTracking()
            .ToListAsync();

        return Result<List<OtomatikAidatDto>>.Ok(list.Select(ToDto).ToList());
    }

    public async Task<Result<OtomatikAidatDto>> UpsertAsync(OtomatikAidatUpsertDto dto)
    {
        if (dto.Tutar <= 0)
            return Result<OtomatikAidatDto>.Fail("Tutar sıfırdan büyük olmalıdır.");

        var kullanici = await db.Kullanicilar.FindAsync(dto.KullaniciId);
        if (kullanici is null)
            return Result<OtomatikAidatDto>.Fail("Kullanıcı bulunamadı.");

        var mevcut = await db.OtomatikAidatlar
            .FirstOrDefaultAsync(o => o.KullaniciId == dto.KullaniciId);

        if (mevcut is not null)
        {
            mevcut.Tutar = dto.Tutar;
            mevcut.AktifMi = true;
            await db.SaveChangesAsync();
            mevcut.Kullanici = kullanici;
            return Result<OtomatikAidatDto>.Ok(ToDto(mevcut), "Otomatik aidat güncellendi.");
        }

        var yeni = new OtomatikAidat
        {
            KullaniciId = dto.KullaniciId,
            Tutar = dto.Tutar,
            AktifMi = true,
        };
        db.OtomatikAidatlar.Add(yeni);
        await db.SaveChangesAsync();
        yeni.Kullanici = kullanici;

        return Result<OtomatikAidatDto>.Ok(ToDto(yeni), "Otomatik aidat oluşturuldu.");
    }

    public async Task<Result<OtomatikAidatDto>> ToggleAktifAsync(int id)
    {
        var kayit = await db.OtomatikAidatlar
            .Include(o => o.Kullanici)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (kayit is null)
            return Result<OtomatikAidatDto>.Fail("Kayıt bulunamadı.");

        kayit.AktifMi = !kayit.AktifMi;
        await db.SaveChangesAsync();

        return Result<OtomatikAidatDto>.Ok(ToDto(kayit));
    }

    public async Task<Result<OtomatikAidatDto>> UpdateTutarAsync(int id, OtomatikAidatTutarGuncelleDto dto)
    {
        if (dto.Tutar <= 0)
            return Result<OtomatikAidatDto>.Fail("Tutar sıfırdan büyük olmalıdır.");

        var kayit = await db.OtomatikAidatlar
            .Include(o => o.Kullanici)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (kayit is null)
            return Result<OtomatikAidatDto>.Fail("Kayıt bulunamadı.");

        kayit.Tutar = dto.Tutar;
        await db.SaveChangesAsync();

        return Result<OtomatikAidatDto>.Ok(ToDto(kayit), "Tutar güncellendi.");
    }

    public async Task<Result> DeleteAsync(int id)
    {
        var kayit = await db.OtomatikAidatlar.FindAsync(id);
        if (kayit is null)
            return Result.Fail("Kayıt bulunamadı.");

        db.OtomatikAidatlar.Remove(kayit);
        await db.SaveChangesAsync();
        return Result.Ok("Otomatik aidat kaldırıldı.");
    }

    public async Task<int> UretAylikAidatlarAsync(int ay, int yil)
    {
        var aktifler = await db.OtomatikAidatlar
            .Where(o => o.AktifMi)
            .ToListAsync();

        int uretilen = 0;

        foreach (var kayit in aktifler)
        {
            // Bu ay/yıl için zaten aidat var mı?
            var varMi = await db.Aidatlar.AnyAsync(a =>
                a.KullaniciId == kayit.KullaniciId &&
                a.Ay == ay && a.Yil == yil);

            if (varMi) continue;

            db.Aidatlar.Add(new Aidat
            {
                KullaniciId = kayit.KullaniciId,
                Tutar = kayit.Tutar,
                Ay = ay,
                Yil = yil,
                OdemeDurumu = OdemeDurumu.Beklemede,
            });

            kayit.SonUretimAy = ay;
            kayit.SonUretimYil = yil;
            uretilen++;
        }

        if (uretilen > 0)
        {
            await db.SaveChangesAsync();
            logger.LogInformation("{Ay}/{Yil} için {Sayi} otomatik aidat oluşturuldu.", ay, yil, uretilen);
        }

        return uretilen;
    }

    private static OtomatikAidatDto ToDto(OtomatikAidat o) => new()
    {
        Id = o.Id,
        KullaniciId = o.KullaniciId,
        KullaniciAdSoyad = $"{o.Kullanici.Ad} {o.Kullanici.Soyad}",
        DaireNo = o.Kullanici.DaireNo,
        Tutar = o.Tutar,
        AktifMi = o.AktifMi,
        SonUretimAy = o.SonUretimAy,
        SonUretimYil = o.SonUretimYil,
    };
}
