using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Data.Context;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Business.Services.Concrete;

public class DaireService(AppDbContext db) : IDaireService
{
    public async Task<Result<List<Daire>>> GetByBlokAsync(int blokId)
    {
        var daireler = await db.Daireler
            .Where(d => d.BlokId == blokId)
            .OrderBy(d => d.DaireNo)
            .AsNoTracking()
            .ToListAsync();

        return Result<List<Daire>>.Ok(daireler);
    }

    public async Task<Result<Daire>> CreateAsync(int blokId, string daireNo)
    {
        daireNo = daireNo.Trim();

        if (string.IsNullOrWhiteSpace(daireNo))
            return Result<Daire>.Fail("Daire numarası boş olamaz.");

        var blokVar = await db.Bloklar.AnyAsync(b => b.Id == blokId);
        if (!blokVar)
            return Result<Daire>.Fail("Blok bulunamadı.");

        var mevcutMu = await db.Daireler
            .AnyAsync(d => d.BlokId == blokId &&
                           d.DaireNo.ToLower() == daireNo.ToLower());
        if (mevcutMu)
            return Result<Daire>.Fail($"Bu blokta '{daireNo}' nolu daire zaten mevcut.");

        var daire = new Daire { BlokId = blokId, DaireNo = daireNo };
        db.Daireler.Add(daire);
        await db.SaveChangesAsync();

        return Result<Daire>.Ok(daire, "Daire eklendi.");
    }

    public async Task<Result> DeleteAsync(int id)
    {
        var daire = await db.Daireler.FindAsync(id);
        if (daire is null)
            return Result.Fail("Daire bulunamadı.");

        db.Daireler.Remove(daire);
        await db.SaveChangesAsync();
        return Result.Ok("Daire silindi.");
    }
}
