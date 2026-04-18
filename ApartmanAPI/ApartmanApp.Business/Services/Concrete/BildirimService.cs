using ApartmanApp.Business.DTOs.Bildirim;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Core.Enums;
using ApartmanApp.Data.Context;
using AutoMapper;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Business.Services.Concrete;

public class BildirimService(AppDbContext db, IFcmService fcm, IMapper mapper) : IBildirimService
{
    public async Task<Result<List<BildirimListDto>>> GetByKullaniciIdAsync(int kullaniciId)
    {
        var bildirimler = await db.Bildirimler
            .Where(b => b.AliciId == kullaniciId)
            .OrderByDescending(b => b.GonderimTarihi)
            .AsNoTracking()
            .ToListAsync();

        return Result<List<BildirimListDto>>.Ok(mapper.Map<List<BildirimListDto>>(bildirimler));
    }

    public async Task<int> GetUnreadCountAsync(int kullaniciId)
    {
        return await db.Bildirimler
            .CountAsync(b => b.AliciId == kullaniciId && !b.Okundu);
    }

    public async Task<Result> MarkAllAsReadAsync(int kullaniciId)
    {
        await db.Bildirimler
            .Where(b => b.AliciId == kullaniciId && !b.Okundu)
            .ExecuteUpdateAsync(s => s.SetProperty(b => b.Okundu, true));
        return Result.Ok("Tüm bildirimler okundu olarak işaretlendi.");
    }

    public async Task<Result> MarkAsReadAsync(int bildirimId, int kullaniciId)
    {
        var bildirim = await db.Bildirimler
            .FirstOrDefaultAsync(b => b.Id == bildirimId && b.AliciId == kullaniciId);

        if (bildirim is null)
            return Result.Fail("Bildirim bulunamadı.");

        bildirim.Okundu = true;
        await db.SaveChangesAsync();
        return Result.Ok("Bildirim okundu olarak işaretlendi.");
    }

    public async Task SendToKullaniciAsync(int aliciId, string baslik, string icerik, string tip)
    {
        var kullanici = await db.Kullanicilar.FindAsync(aliciId);
        if (kullanici is null) return;

        var bildirim = new Bildirim
        {
            AliciId = aliciId,
            Baslik = baslik,
            Icerik = icerik,
            Tip = tip,
            GonderimTarihi = DateTime.UtcNow,
            Okundu = false,
        };
        db.Bildirimler.Add(bildirim);
        await db.SaveChangesAsync();

        await fcm.SendAsync(kullanici.FcmToken, baslik, icerik, tip);
    }

    public async Task SendToAllSakinlerAsync(string baslik, string icerik)
    {
        var sakinler = await db.Kullanicilar
            .Where(k => k.Rol == KullaniciRol.Sakin)
            .ToListAsync();

        var bildirimler = sakinler.Select(s => new Bildirim
        {
            AliciId = s.Id,
            Baslik = baslik,
            Icerik = icerik,
            Tip = "Duyuru",
            GonderimTarihi = DateTime.UtcNow,
            Okundu = false,
        }).ToList();

        db.Bildirimler.AddRange(bildirimler);
        await db.SaveChangesAsync();

        // FCM paralel gönder
        var fcmTasks = sakinler.Select(s => fcm.SendAsync(s.FcmToken, baslik, icerik, "Duyuru"));
        await Task.WhenAll(fcmTasks);
    }

    public async Task SendToBlokAsync(string blokNo, string baslik, string icerik)
    {
        var kullanicilar = await db.Kullanicilar
            .Where(k => k.Rol == KullaniciRol.Sakin && k.BlokNo == blokNo)
            .ToListAsync();

        if (kullanicilar.Count == 0) return;

        var bildirimler = kullanicilar.Select(k => new Bildirim
        {
            AliciId = k.Id,
            Baslik = baslik,
            Icerik = icerik,
            Tip = "BlokMesaj",
            GonderimTarihi = DateTime.UtcNow,
            Okundu = false,
        }).ToList();

        db.Bildirimler.AddRange(bildirimler);
        await db.SaveChangesAsync();

        var fcmTasks = kullanicilar.Select(k => fcm.SendAsync(k.FcmToken, baslik, icerik, "BlokMesaj"));
        await Task.WhenAll(fcmTasks);
    }

    public async Task SendToDaireAsync(string daireNo, string baslik, string icerik, string? blokNo = null)
    {
        var query = db.Kullanicilar.Where(k => k.DaireNo == daireNo);
        if (!string.IsNullOrWhiteSpace(blokNo))
            query = query.Where(k => k.BlokNo == blokNo);

        var kullanicilar = await query.ToListAsync();

        if (kullanicilar.Count == 0) return;

        var bildirimler = kullanicilar.Select(k => new Bildirim
        {
            AliciId = k.Id,
            Baslik = baslik,
            Icerik = icerik,
            Tip = "DaireMesaj",
            GonderimTarihi = DateTime.UtcNow,
            Okundu = false,
        }).ToList();

        db.Bildirimler.AddRange(bildirimler);
        await db.SaveChangesAsync();

        var fcmTasks = kullanicilar.Select(k => fcm.SendAsync(k.FcmToken, baslik, icerik, "DaireMesaj"));
        await Task.WhenAll(fcmTasks);
    }

    public async Task SendToAdminlerAsync(string baslik, string icerik, string tip)
    {
        var adminler = await db.Kullanicilar
            .Where(k => k.Rol == KullaniciRol.Admin)
            .ToListAsync();

        var bildirimler = adminler.Select(a => new Bildirim
        {
            AliciId = a.Id,
            Baslik = baslik,
            Icerik = icerik,
            Tip = tip,
            GonderimTarihi = DateTime.UtcNow,
            Okundu = false,
        }).ToList();

        db.Bildirimler.AddRange(bildirimler);
        await db.SaveChangesAsync();

        var fcmTasks = adminler.Select(a => fcm.SendAsync(a.FcmToken, baslik, icerik, tip));
        await Task.WhenAll(fcmTasks);
    }

    public async Task SendToTakipcilerAsync(int arizaId, string baslik, string icerik, string tip, int? excludeKullaniciId = null)
    {
        var takipler = await db.ArizaTakipler
            .Include(t => t.Kullanici)
            .Where(t => t.ArizaId == arizaId && (excludeKullaniciId == null || t.KullaniciId != excludeKullaniciId))
            .ToListAsync();

        if (takipler.Count == 0) return;

        var bildirimler = takipler.Select(t => new Bildirim
        {
            AliciId = t.KullaniciId,
            Baslik = baslik,
            Icerik = icerik,
            Tip = tip,
            GonderimTarihi = DateTime.UtcNow,
            Okundu = false,
        }).ToList();

        db.Bildirimler.AddRange(bildirimler);
        await db.SaveChangesAsync();

        var fcmTasks = takipler.Select(t => fcm.SendAsync(t.Kullanici!.FcmToken, baslik, icerik, tip));
        await Task.WhenAll(fcmTasks);
    }
}
