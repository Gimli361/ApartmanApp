using ApartmanApp.Business.DTOs.Kullanici;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Data.Context;
using AutoMapper;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Business.Services.Concrete;

public class KullaniciService(AppDbContext db, IMapper mapper) : IKullaniciService
{
    public async Task<Result<List<KullaniciListDto>>> GetAllAsync()
    {
        var kullanicilar = await db.Kullanicilar
            .OrderBy(k => k.Ad)
            .AsNoTracking()
            .ToListAsync();

        return Result<List<KullaniciListDto>>.Ok(mapper.Map<List<KullaniciListDto>>(kullanicilar));
    }

    public async Task<Result<KullaniciListDto>> GetByIdAsync(int id)
    {
        var kullanici = await db.Kullanicilar
            .AsNoTracking()
            .FirstOrDefaultAsync(k => k.Id == id);

        if (kullanici is null)
            return Result<KullaniciListDto>.Fail("Kullanıcı bulunamadı.");

        return Result<KullaniciListDto>.Ok(mapper.Map<KullaniciListDto>(kullanici));
    }

    public async Task<Result<KullaniciListDto>> CreateAsync(KullaniciCreateDto dto)
    {
        var emailKullanımda = await db.Kullanicilar.AnyAsync(k => k.Email == dto.Email);
        if (emailKullanımda)
            return Result<KullaniciListDto>.Fail("Bu email adresi zaten kayıtlı.");

        var kullanici = mapper.Map<Kullanici>(dto);
        kullanici.SifreHash = BCrypt.Net.BCrypt.HashPassword(dto.Sifre);
        db.Kullanicilar.Add(kullanici);
        await db.SaveChangesAsync();

        return Result<KullaniciListDto>.Ok(mapper.Map<KullaniciListDto>(kullanici), "Kullanıcı oluşturuldu.");
    }

    public async Task<Result<KullaniciListDto>> UpdateAsync(int id, KullaniciUpdateDto dto)
    {
        var kullanici = await db.Kullanicilar.FindAsync(id);
        if (kullanici is null)
            return Result<KullaniciListDto>.Fail("Kullanıcı bulunamadı.");

        if (!string.IsNullOrWhiteSpace(dto.Ad)) kullanici.Ad = dto.Ad;
        if (!string.IsNullOrWhiteSpace(dto.Soyad)) kullanici.Soyad = dto.Soyad;
        if (!string.IsNullOrWhiteSpace(dto.DaireNo)) kullanici.DaireNo = dto.DaireNo;
        kullanici.BlokNo = dto.BlokNo; // null atanabilir (bloğu kaldırmak için)

        await db.SaveChangesAsync();
        return Result<KullaniciListDto>.Ok(mapper.Map<KullaniciListDto>(kullanici), "Bilgiler güncellendi.");
    }

    public async Task<Result> UpdateSifreAsync(int id, SifreGuncelleDto dto)
    {
        var kullanici = await db.Kullanicilar.FindAsync(id);
        if (kullanici is null)
            return Result.Fail("Kullanıcı bulunamadı.");

        if (!BCrypt.Net.BCrypt.Verify(dto.EskiSifre, kullanici.SifreHash))
            return Result.Fail("Mevcut şifre yanlış.");

        kullanici.SifreHash = BCrypt.Net.BCrypt.HashPassword(dto.YeniSifre);
        await db.SaveChangesAsync();

        return Result.Ok("Şifre güncellendi.");
    }

    public async Task<Result> AdminSifreSifirlaAsync(int id, string yeniSifre)
    {
        if (string.IsNullOrWhiteSpace(yeniSifre))
            return Result.Fail("Yeni şifre boş olamaz.");

        var kullanici = await db.Kullanicilar.FindAsync(id);
        if (kullanici is null)
            return Result.Fail("Kullanıcı bulunamadı.");

        kullanici.SifreHash = BCrypt.Net.BCrypt.HashPassword(yeniSifre);
        await db.SaveChangesAsync();

        return Result.Ok("Şifre sıfırlandı.");
    }

    public async Task<Result> UpdateFcmTokenAsync(int id, string token)
    {
        var kullanici = await db.Kullanicilar.FindAsync(id);
        if (kullanici is null)
            return Result.Fail("Kullanıcı bulunamadı.");

        kullanici.FcmToken = token;
        await db.SaveChangesAsync();
        return Result.Ok("FCM token güncellendi.");
    }

    public async Task<Result> DeleteAsync(int id)
    {
        var kullanici = await db.Kullanicilar.FindAsync(id);
        if (kullanici is null)
            return Result.Fail("Kullanıcı bulunamadı.");

        var aktifAriza = await db.Arizalar.AnyAsync(a => a.BildirenId == id);
        if (aktifAriza)
            return Result.Fail("Bu kullanıcıya ait arızalar mevcut. Önce arızaları siliniz.");

        db.Kullanicilar.Remove(kullanici);
        await db.SaveChangesAsync();

        return Result.Ok("Kullanıcı silindi.");
    }
}
