using ApartmanApp.Business.DTOs.Ariza;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Core.Enums;
using ApartmanApp.Data.Context;
using ApartmanApp.Data.Extensions;
using AutoMapper;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Business.Services.Concrete;

public class ArizaService(AppDbContext db, IMapper mapper, IBildirimService bildirimService) : IArizaService
{
    public async Task<Result<List<ArizaListDto>>> GetAllAsync(string? blokNo = null)
    {
        var query = db.Arizalar
            .Include(a => a.Bildiren)
            .Include(a => a.Takipler)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(blokNo))
            query = query.Where(a => a.BlokNo == blokNo);

        var arizalar = await query
            .OrderByDescending(a => a.Tarih)
            .AsNoTracking()
            .ToListAsync();

        var dtos = mapper.Map<List<ArizaListDto>>(arizalar);
        for (int i = 0; i < arizalar.Count; i++)
            dtos[i].TakipciSayisi = arizalar[i].Takipler.Count;

        return Result<List<ArizaListDto>>.Ok(dtos);
    }

    public async Task<Result<PagedResult<ArizaListDto>>> GetPagedAsync(int page, int pageSize, string? blokNo = null)
    {
        var query = db.Arizalar
            .Include(a => a.Bildiren)
            .Include(a => a.Takipler)
            .AsNoTracking()
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(blokNo))
            query = query.Where(a => a.BlokNo == blokNo);

        var paged = await query
            .OrderByDescending(a => a.Tarih)
            .ToPagedResultAsync(page, pageSize);

        var items = mapper.Map<List<ArizaListDto>>(paged.Items);
        for (int i = 0; i < paged.Items.Count; i++)
            items[i].TakipciSayisi = paged.Items[i].Takipler.Count;

        var result = new PagedResult<ArizaListDto>
        {
            Items = items,
            Page = paged.Page,
            PageSize = paged.PageSize,
            TotalCount = paged.TotalCount
        };
        return Result<PagedResult<ArizaListDto>>.Ok(result);
    }

    public async Task<Result<ArizaDetailDto>> GetByIdAsync(int id)
    {
        var ariza = await db.Arizalar
            .Include(a => a.Bildiren)
            .Include(a => a.Takipler)
            .AsNoTracking()
            .FirstOrDefaultAsync(a => a.Id == id);

        if (ariza is null)
            return Result<ArizaDetailDto>.Fail("Arıza bulunamadı.");

        var dto = mapper.Map<ArizaDetailDto>(ariza);
        dto.TakipciSayisi = ariza.Takipler.Count;
        return Result<ArizaDetailDto>.Ok(dto);
    }

    public async Task<Result<ArizaDetailDto>> CreateAsync(ArizaCreateDto dto)
    {
        var bildiren = await db.Kullanicilar.FindAsync(dto.BildirenId);
        if (bildiren is null)
            return Result<ArizaDetailDto>.Fail("Bildiren kullanıcı bulunamadı.");

        var ariza = mapper.Map<Ariza>(dto);
        ariza.Tarih = DateTime.UtcNow;
        ariza.BlokNo = dto.OrtakAlan ? null : bildiren.BlokNo;

        db.Arizalar.Add(ariza);
        await db.SaveChangesAsync();

        ariza.Bildiren = bildiren;

        // Yeni arıza → tüm adminlere bildirim
        await bildirimService.SendToAdminlerAsync(
            "Yeni Arıza Bildirimi",
            $"{ariza.Bildiren?.DaireNo ?? "?"} - {ariza.Baslik}",
            "YeniAriza");

        var resultDto = mapper.Map<ArizaDetailDto>(ariza);
        return Result<ArizaDetailDto>.Ok(resultDto, "Arıza başarıyla oluşturuldu.");
    }

    public async Task<Result<ArizaDetailDto>> UpdateDurumAsync(int id, ArizaDurumGuncelleDto dto)
    {
        var ariza = await db.Arizalar
            .Include(a => a.Bildiren)
            .Include(a => a.Takipler)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (ariza is null)
            return Result<ArizaDetailDto>.Fail("Arıza bulunamadı.");

        var eskiDurum = ariza.Durum;
        ariza.Durum = dto.Durum;

        if (dto.Durum == ArizaDurum.Reddedildi && !string.IsNullOrWhiteSpace(dto.RedNedeni))
            ariza.RedNedeni = dto.RedNedeni;

        await db.SaveChangesAsync();

        var durumMesaj = dto.Durum == ArizaDurum.Reddedildi && !string.IsNullOrWhiteSpace(dto.RedNedeni)
            ? $"\"{ariza.Baslik}\" arızası reddedildi. Neden: {dto.RedNedeni}"
            : $"\"{ariza.Baslik}\" arızanızın durumu {eskiDurum} → {dto.Durum} olarak güncellendi.";

        // Bildirene bildirim
        if (ariza.BildirenId != 0)
            await bildirimService.SendToKullaniciAsync(ariza.BildirenId, "Arıza Durumu Güncellendi", durumMesaj, "ArizaDurum");

        // Takipçilere bildirim (bildirene ayrıca gönderildiğinden hariç tut)
        await bildirimService.SendToTakipcilerAsync(ariza.Id, "Takip Ettiğiniz Arıza Güncellendi", durumMesaj, "ArizaDurum", excludeKullaniciId: ariza.BildirenId);

        var resultDto = mapper.Map<ArizaDetailDto>(ariza);
        resultDto.TakipciSayisi = ariza.Takipler.Count;
        return Result<ArizaDetailDto>.Ok(resultDto, "Arıza durumu güncellendi.");
    }

    public async Task<Result> DeleteAsync(int id)
    {
        var ariza = await db.Arizalar.FindAsync(id);
        if (ariza is null)
            return Result.Fail("Arıza bulunamadı.");

        db.Arizalar.Remove(ariza);
        await db.SaveChangesAsync();

        return Result.Ok("Arıza silindi.");
    }
}
