using ApartmanApp.Business.DTOs.Aidat;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Core.Enums;
using ApartmanApp.Data.Context;
using ApartmanApp.Data.Extensions;
using AutoMapper;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Business.Services.Concrete;

public class AidatService(AppDbContext db, IMapper mapper) : IAidatService
{
    public async Task<Result<List<AidatListDto>>> GetAllAsync()
    {
        var aidatlar = await db.Aidatlar
            .Include(a => a.Kullanici)
            .OrderByDescending(a => a.Yil).ThenByDescending(a => a.Ay)
            .AsNoTracking()
            .ToListAsync();

        return Result<List<AidatListDto>>.Ok(mapper.Map<List<AidatListDto>>(aidatlar));
    }

    public async Task<Result<List<AidatListDto>>> GetByKullaniciIdAsync(int kullaniciId)
    {
        var aidatlar = await db.Aidatlar
            .Include(a => a.Kullanici)
            .Where(a => a.KullaniciId == kullaniciId)
            .OrderByDescending(a => a.Yil).ThenByDescending(a => a.Ay)
            .AsNoTracking()
            .ToListAsync();

        return Result<List<AidatListDto>>.Ok(mapper.Map<List<AidatListDto>>(aidatlar));
    }

    public async Task<Result<PagedResult<AidatListDto>>> GetPagedAsync(int page, int pageSize)
    {
        var paged = await db.Aidatlar
            .Include(a => a.Kullanici)
            .OrderByDescending(a => a.Yil).ThenByDescending(a => a.Ay)
            .AsNoTracking()
            .ToPagedResultAsync(page, pageSize);

        var result = new PagedResult<AidatListDto>
        {
            Items = mapper.Map<List<AidatListDto>>(paged.Items),
            Page = paged.Page,
            PageSize = paged.PageSize,
            TotalCount = paged.TotalCount
        };
        return Result<PagedResult<AidatListDto>>.Ok(result);
    }

    public async Task<Result<PagedResult<AidatListDto>>> GetPagedByKullaniciIdAsync(int kullaniciId, int page, int pageSize)
    {
        var paged = await db.Aidatlar
            .Include(a => a.Kullanici)
            .Where(a => a.KullaniciId == kullaniciId)
            .OrderByDescending(a => a.Yil).ThenByDescending(a => a.Ay)
            .AsNoTracking()
            .ToPagedResultAsync(page, pageSize);

        var result = new PagedResult<AidatListDto>
        {
            Items = mapper.Map<List<AidatListDto>>(paged.Items),
            Page = paged.Page,
            PageSize = paged.PageSize,
            TotalCount = paged.TotalCount
        };
        return Result<PagedResult<AidatListDto>>.Ok(result);
    }

    public async Task<Result<AidatListDto>> GetByIdAsync(int id)
    {
        var aidat = await db.Aidatlar
            .Include(a => a.Kullanici)
            .AsNoTracking()
            .FirstOrDefaultAsync(a => a.Id == id);

        if (aidat is null)
            return Result<AidatListDto>.Fail("Aidat kaydı bulunamadı.");

        return Result<AidatListDto>.Ok(mapper.Map<AidatListDto>(aidat));
    }

    public async Task<Result<AidatListDto>> CreateAsync(AidatCreateDto dto)
    {
        if (dto.Ay < 1 || dto.Ay > 12)
            return Result<AidatListDto>.Fail("Ay 1-12 arasında olmalıdır.");

        if (dto.Tutar <= 0)
            return Result<AidatListDto>.Fail("Tutar sıfırdan büyük olmalıdır.");

        var kullanici = await db.Kullanicilar.FindAsync(dto.KullaniciId);
        if (kullanici is null)
            return Result<AidatListDto>.Fail("Kullanıcı bulunamadı.");

        var duplikat = await db.Aidatlar.AnyAsync(a =>
            a.KullaniciId == dto.KullaniciId && a.Ay == dto.Ay && a.Yil == dto.Yil);
        if (duplikat)
            return Result<AidatListDto>.Fail($"Bu kullanıcı için {dto.Ay}/{dto.Yil} dönemi aidat kaydı zaten mevcut.");

        var aidat = new Aidat
        {
            KullaniciId = dto.KullaniciId,
            Tutar = dto.Tutar,
            Ay = dto.Ay,
            Yil = dto.Yil,
            OdemeDurumu = OdemeDurumu.Beklemede,
        };

        db.Aidatlar.Add(aidat);
        await db.SaveChangesAsync();
        aidat.Kullanici = kullanici;

        return Result<AidatListDto>.Ok(mapper.Map<AidatListDto>(aidat), "Aidat kaydı oluşturuldu.");
    }

    public async Task<Result<AidatListDto>> UpdateOdemeDurumAsync(int id, AidatOdemeDurumGuncelleDto dto)
    {
        var aidat = await db.Aidatlar
            .Include(a => a.Kullanici)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (aidat is null)
            return Result<AidatListDto>.Fail("Aidat kaydı bulunamadı.");

        aidat.OdemeDurumu = dto.OdemeDurumu;
        aidat.OdemeTarihi = dto.OdemeDurumu == OdemeDurumu.Odendi ? DateTime.UtcNow : null;
        await db.SaveChangesAsync();

        return Result<AidatListDto>.Ok(mapper.Map<AidatListDto>(aidat), "Ödeme durumu güncellendi.");
    }

    public async Task<Result> DeleteAsync(int id)
    {
        var aidat = await db.Aidatlar.FindAsync(id);
        if (aidat is null)
            return Result.Fail("Aidat kaydı bulunamadı.");

        db.Aidatlar.Remove(aidat);
        await db.SaveChangesAsync();

        return Result.Ok("Aidat kaydı silindi.");
    }
}
