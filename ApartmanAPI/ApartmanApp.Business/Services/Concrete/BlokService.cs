using ApartmanApp.Business.DTOs.Bina;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Data.Context;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Business.Services.Concrete;

public class BlokService(AppDbContext db) : IBlokService
{
    public async Task<Result<List<Blok>>> GetAllAsync()
    {
        var bloklar = await db.Bloklar
            .Include(b => b.Daireler.OrderBy(d => d.DaireNo))
            .OrderBy(b => b.Ad)
            .AsNoTracking()
            .ToListAsync();
        return Result<List<Blok>>.Ok(bloklar);
    }

    public async Task<Result<List<BlokDetayDto>>> GetAllWithSakinlerAsync()
    {
        var bloklar = await db.Bloklar
            .Include(b => b.Daireler.OrderBy(d => d.DaireNo))
            .OrderBy(b => b.Ad)
            .AsNoTracking()
            .ToListAsync();

        var kullanicilar = await db.Kullanicilar
            .AsNoTracking()
            .ToListAsync();

        var dtos = bloklar.Select(b => new BlokDetayDto
        {
            Id = b.Id,
            Ad = b.Ad,
            Daireler = b.Daireler.Select(d =>
            {
                var tamDaireNo = b.Ad + d.DaireNo;
                var sakin = kullanicilar.FirstOrDefault(k =>
                    k.DaireNo == tamDaireNo ||
                    (k.BlokNo == b.Ad && k.DaireNo == d.DaireNo));
                return new DaireDetayDto
                {
                    Id = d.Id,
                    DaireNo = d.DaireNo,
                    Sakin = sakin is null ? null : new SakinOzetDto
                    {
                        Id = sakin.Id,
                        AdSoyad = $"{sakin.Ad} {sakin.Soyad}".Trim(),
                        Email = sakin.Email,
                        Rol = sakin.Rol.ToString(),
                    }
                };
            }).ToList()
        }).ToList();

        return Result<List<BlokDetayDto>>.Ok(dtos);
    }

    public async Task<Result<Blok>> CreateAsync(string ad)
    {
        ad = ad.Trim();
        if (string.IsNullOrWhiteSpace(ad))
            return Result<Blok>.Fail("Blok adı boş olamaz.");

        if (await db.Bloklar.AnyAsync(b => b.Ad.ToLower() == ad.ToLower()))
            return Result<Blok>.Fail($"'{ad}' bloku zaten tanımlı.");

        var blok = new Blok { Ad = ad };
        db.Bloklar.Add(blok);
        await db.SaveChangesAsync();
        return Result<Blok>.Ok(blok, "Blok eklendi.");
    }

    public async Task<Result> DeleteAsync(int id)
    {
        var blok = await db.Bloklar.FindAsync(id);
        if (blok is null)
            return Result.Fail("Blok bulunamadı.");

        db.Bloklar.Remove(blok);
        await db.SaveChangesAsync();
        return Result.Ok("Blok silindi.");
    }
}
