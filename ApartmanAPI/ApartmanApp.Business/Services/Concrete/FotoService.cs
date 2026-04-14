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

        var yuklemeKlasoru = Path.Combine("wwwroot", "uploads", "arizalar", arizaId.ToString());
        Directory.CreateDirectory(yuklemeKlasoru);

        var benzersizAd = $"{Guid.NewGuid()}{uzanti}";
        var tamYol = Path.Combine(yuklemeKlasoru, benzersizAd);

        await using (var stream = new FileStream(tamYol, FileMode.Create))
        {
            await dosya.CopyToAsync(stream);
        }

        var foto = new ArizaFoto
        {
            ArizaId = arizaId,
            DosyaAdi = dosya.FileName,
            DosyaYolu = tamYol,
            DosyaBoyutu = dosya.Length,
            YuklemeTarihi = DateTime.UtcNow
        };

        db.ArizaFotolar.Add(foto);
        await db.SaveChangesAsync();

        return Result<ArizaFotoDto>.Ok(ToDto(foto), "Fotoğraf yüklendi.");
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
