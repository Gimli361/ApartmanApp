using ApartmanApp.Business.DTOs.Ariza;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Data.Context;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Business.Services.Concrete;

public class FotoService(AppDbContext db, IHttpContextAccessor httpContextAccessor) : IFotoService
{
    private static readonly string[] IzinliUzantilar = [".jpg", ".jpeg", ".png", ".webp"];
    private static readonly string[] IzinliMimeTipleri =
        ["image/jpeg", "image/png", "image/webp"];
    private const long MaksimumBoyut = 5 * 1024 * 1024; // 5 MB

    public async Task<Result<ArizaFotoDto>> UploadAsync(int arizaId, IFormFile dosya)
    {
        var arizaVar = await db.Arizalar.AnyAsync(a => a.Id == arizaId);
        if (!arizaVar)
            return Result<ArizaFotoDto>.Fail("Arıza bulunamadı.");

        if (dosya.Length == 0)
            return Result<ArizaFotoDto>.Fail("Dosya boş olamaz.");

        if (dosya.Length > MaksimumBoyut)
            return Result<ArizaFotoDto>.Fail("Dosya boyutu 5 MB'ı geçemez.");

        var uzanti = Path.GetExtension(dosya.FileName).ToLowerInvariant();
        if (!IzinliUzantilar.Contains(uzanti))
            return Result<ArizaFotoDto>.Fail("Sadece .jpg, .jpeg, .png ve .webp dosyaları yüklenebilir.");

        if (!IzinliMimeTipleri.Contains(dosya.ContentType?.ToLowerInvariant()))
            return Result<ArizaFotoDto>.Fail("Geçersiz dosya tipi.");

        // Magic-byte (gerçek içerik) kontrolü — uzantı sahteleme engeli
        await using (var probeStream = dosya.OpenReadStream())
        {
            var imzaTipi = await DetectImageSignatureAsync(probeStream);
            if (imzaTipi is null)
                return Result<ArizaFotoDto>.Fail("Dosya içeriği geçerli bir görsel değil.");
            if (imzaTipi != uzanti && !(imzaTipi == ".jpg" && uzanti == ".jpeg"))
                return Result<ArizaFotoDto>.Fail("Dosya uzantısı içeriğiyle eşleşmiyor.");
        }

        var yuklemeKlasoru = Path.Combine("wwwroot", "uploads", "arizalar", arizaId.ToString());
        Directory.CreateDirectory(yuklemeKlasoru);

        var benzersizAd = $"{Guid.NewGuid()}{uzanti}";
        var tamYol = Path.Combine(yuklemeKlasoru, benzersizAd);

        await using (var stream = new FileStream(tamYol, FileMode.Create))
        {
            await dosya.CopyToAsync(stream);
        }

        // Orijinal dosya adını sanitize et (XSS / yol enjeksiyonu önleme)
        var guvenliAd = Path.GetFileName(dosya.FileName);
        if (guvenliAd.Length > 100) guvenliAd = guvenliAd[..100];

        var foto = new ArizaFoto
        {
            ArizaId = arizaId,
            DosyaAdi = guvenliAd,
            DosyaYolu = tamYol,
            DosyaBoyutu = dosya.Length,
            YuklemeTarihi = DateTime.UtcNow
        };

        db.ArizaFotolar.Add(foto);
        await db.SaveChangesAsync();

        return Result<ArizaFotoDto>.Ok(ToDto(foto), "Fotoğraf yüklendi.");
    }

    private static async Task<string?> DetectImageSignatureAsync(Stream stream)
    {
        var buffer = new byte[12];
        var read = await stream.ReadAsync(buffer.AsMemory(0, 12));
        if (read < 4) return null;

        // JPEG: FF D8 FF
        if (buffer[0] == 0xFF && buffer[1] == 0xD8 && buffer[2] == 0xFF)
            return ".jpg";
        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (read >= 8 &&
            buffer[0] == 0x89 && buffer[1] == 0x50 && buffer[2] == 0x4E && buffer[3] == 0x47 &&
            buffer[4] == 0x0D && buffer[5] == 0x0A && buffer[6] == 0x1A && buffer[7] == 0x0A)
            return ".png";
        // WEBP: "RIFF" .... "WEBP"
        if (read >= 12 &&
            buffer[0] == 0x52 && buffer[1] == 0x49 && buffer[2] == 0x46 && buffer[3] == 0x46 &&
            buffer[8] == 0x57 && buffer[9] == 0x45 && buffer[10] == 0x42 && buffer[11] == 0x50)
            return ".webp";
        return null;
    }

    public async Task<Result<List<ArizaFotoDto>>> GetByArizaIdAsync(int arizaId)
    {
        var arizaVar = await db.Arizalar.AnyAsync(a => a.Id == arizaId);
        if (!arizaVar)
            return Result<List<ArizaFotoDto>>.Fail("Arıza bulunamadı.");

        var fotolar = await db.ArizaFotolar
            .Where(f => f.ArizaId == arizaId)
            .OrderByDescending(f => f.YuklemeTarihi)
            .AsNoTracking()
            .ToListAsync();

        return Result<List<ArizaFotoDto>>.Ok(fotolar.Select(ToDto).ToList());
    }

    public async Task<Result> DeleteAsync(int fotoId)
    {
        var foto = await db.ArizaFotolar.FindAsync(fotoId);
        if (foto is null)
            return Result.Fail("Fotoğraf bulunamadı.");

        if (File.Exists(foto.DosyaYolu))
            File.Delete(foto.DosyaYolu);

        db.ArizaFotolar.Remove(foto);
        await db.SaveChangesAsync();

        return Result.Ok("Fotoğraf silindi.");
    }

    private ArizaFotoDto ToDto(ArizaFoto foto)
    {
        var request = httpContextAccessor.HttpContext?.Request;
        var baseUrl = request is not null
            ? $"{request.Scheme}://{request.Host}"
            : string.Empty;

        var relativePath = foto.DosyaYolu
            .Replace("wwwroot", string.Empty)
            .Replace('\\', '/');

        return new ArizaFotoDto
        {
            Id = foto.Id,
            ArizaId = foto.ArizaId,
            DosyaAdi = foto.DosyaAdi,
            DosyaBoyutu = foto.DosyaBoyutu,
            YuklemeTarihi = foto.YuklemeTarihi,
            Url = baseUrl + relativePath
        };
    }
}
