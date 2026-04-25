using ApartmanApp.Business.DTOs.Oylama;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Data.Context;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Business.Services.Concrete;

public class OylamaService(AppDbContext db) : IOylamaService
{
    public async Task<Result<List<OylamaListDto>>> GetAllAsync(int kullaniciId)
    {
        var oylamalar = await db.Oylamalar
            .Include(o => o.Oylar)
            .OrderByDescending(o => o.BaslangicTarihi)
            .ToListAsync();

        var dtos = oylamalar.Select(o => new OylamaListDto
        {
            Id = o.Id,
            Baslik = o.Baslik,
            Aciklama = o.Aciklama,
            BaslangicTarihi = o.BaslangicTarihi,
            BitisTarihi = o.BitisTarihi,
            AktifMi = o.AktifMi,
            ToplamOySayisi = o.Oylar.Count,
            KullaniciOyKullandi = o.Oylar.Any(oy => oy.KullaniciId == kullaniciId),
        }).ToList();

        return Result<List<OylamaListDto>>.Ok(dtos);
    }

    public async Task<Result<OylamaDetailDto>> GetByIdAsync(int id, int kullaniciId)
    {
        var oylama = await db.Oylamalar
            .Include(o => o.Secenekler)
                .ThenInclude(s => s.Oylar)
            .Include(o => o.Oylar)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (oylama is null)
            return Result<OylamaDetailDto>.Fail("Oylama bulunamadı.");

        var kullaniciOyu = oylama.Oylar.FirstOrDefault(oy => oy.KullaniciId == kullaniciId);
        var toplamOy = oylama.Oylar.Count;

        var dto = new OylamaDetailDto
        {
            Id = oylama.Id,
            Baslik = oylama.Baslik,
            Aciklama = oylama.Aciklama,
            BaslangicTarihi = oylama.BaslangicTarihi,
            BitisTarihi = oylama.BitisTarihi,
            AktifMi = oylama.AktifMi,
            OlusturanId = oylama.OlusturanId,
            ToplamOySayisi = toplamOy,
            KullaniciOyKullandi = kullaniciOyu is not null,
            KullaniciSecenekId = kullaniciOyu?.SecenekId,
            Secenekler = oylama.Secenekler.Select(s => new OylamaSecenekDto
            {
                Id = s.Id,
                Metin = s.Metin,
                OySayisi = s.Oylar.Count,
                OranYuzde = toplamOy > 0
                    ? Math.Round((double)s.Oylar.Count / toplamOy * 100, 1)
                    : 0,
            }).ToList(),
        };

        return Result<OylamaDetailDto>.Ok(dto);
    }

    public async Task<Result<OylamaDetailDto>> CreateAsync(OylamaCreateDto dto, int olusturanId)
    {
        if (string.IsNullOrWhiteSpace(dto.Baslik))
            return Result<OylamaDetailDto>.Fail("Başlık zorunludur.");

        if (dto.Secenekler.Count < 2)
            return Result<OylamaDetailDto>.Fail("En az 2 seçenek girilmelidir.");

        if (dto.BitisTarihi <= DateTime.UtcNow)
            return Result<OylamaDetailDto>.Fail("Bitiş tarihi gelecekte olmalıdır.");

        var oylama = new Oylama
        {
            Baslik = dto.Baslik,
            Aciklama = dto.Aciklama,
            BaslangicTarihi = DateTime.UtcNow,
            BitisTarihi = dto.BitisTarihi,
            OlusturanId = olusturanId,
            AktifMi = true,
            Secenekler = dto.Secenekler
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .Select(s => new OylamaSecenek { Metin = s.Trim() })
                .ToList(),
        };

        db.Oylamalar.Add(oylama);
        await db.SaveChangesAsync();

        return await GetByIdAsync(oylama.Id, olusturanId);
    }

    public async Task<Result> OyVerAsync(int oylamaId, int secenekId, int kullaniciId)
    {
        var oylama = await db.Oylamalar
            .Include(o => o.Secenekler)
            .Include(o => o.Oylar)
            .FirstOrDefaultAsync(o => o.Id == oylamaId);

        if (oylama is null)
            return Result.Fail("Oylama bulunamadı.");

        if (!oylama.AktifMi || oylama.BitisTarihi < DateTime.UtcNow)
            return Result.Fail("Bu oylama aktif değil veya süresi dolmuş.");

        if (oylama.Oylar.Any(oy => oy.KullaniciId == kullaniciId))
            return Result.Fail("Bu oylamaya zaten oy kullandınız.");

        if (oylama.Secenekler.All(s => s.Id != secenekId))
            return Result.Fail("Geçersiz seçenek.");

        db.OylamaOylari.Add(new OylamaOyu
        {
            OylamaId = oylamaId,
            SecenekId = secenekId,
            KullaniciId = kullaniciId,
            OyTarihi = DateTime.UtcNow,
        });

        try
        {
            await db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            // Concurrent istekte unique index ihlali — kullanıcı zaten oy vermiş
            return Result.Fail("Bu oylamaya zaten oy kullandınız.");
        }
        return Result.Ok("Oyunuz kaydedildi.");
    }

    public async Task<Result> OyGeriAlAsync(int oylamaId, int kullaniciId)
    {
        var oy = await db.OylamaOylari
            .FirstOrDefaultAsync(o => o.OylamaId == oylamaId && o.KullaniciId == kullaniciId);

        if (oy is null)
            return Result.Fail("Oy kaydı bulunamadı.");

        var oylama = await db.Oylamalar.FindAsync(oylamaId);
        if (oylama is null || !oylama.AktifMi || oylama.BitisTarihi < DateTime.UtcNow)
            return Result.Fail("Aktif olmayan bir oylamada oy geri alınamaz.");

        db.OylamaOylari.Remove(oy);
        await db.SaveChangesAsync();
        return Result.Ok("Oyunuz geri alındı.");
    }

    public async Task<Result> DeleteAsync(int id)
    {
        var oylama = await db.Oylamalar.FindAsync(id);
        if (oylama is null)
            return Result.Fail("Oylama bulunamadı.");

        db.Oylamalar.Remove(oylama);
        await db.SaveChangesAsync();
        return Result.Ok("Oylama silindi.");
    }

    public async Task<Result> ToggleAktifAsync(int id)
    {
        var oylama = await db.Oylamalar.FindAsync(id);
        if (oylama is null)
            return Result.Fail("Oylama bulunamadı.");

        oylama.AktifMi = !oylama.AktifMi;
        await db.SaveChangesAsync();
        return Result.Ok(oylama.AktifMi ? "Oylama aktif edildi." : "Oylama pasif edildi.");
    }
}
