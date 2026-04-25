using ApartmanApp.Business.DTOs.Aidat;
using ApartmanApp.Core.Common;

namespace ApartmanApp.Business.Services.Abstract;

public interface IAidatService
{
    Task<Result<List<AidatListDto>>> GetAllAsync();
    Task<Result<PagedResult<AidatListDto>>> GetPagedAsync(int page, int pageSize);
    Task<Result<List<AidatListDto>>> GetByKullaniciIdAsync(int kullaniciId);
    Task<Result<PagedResult<AidatListDto>>> GetPagedByKullaniciIdAsync(int kullaniciId, int page, int pageSize);
    Task<Result<AidatListDto>> GetByIdAsync(int id);
    Task<Result<AidatListDto>> CreateAsync(AidatCreateDto dto);
    Task<Result<AidatListDto>> UpdateOdemeDurumAsync(int id, AidatOdemeDurumGuncelleDto dto);
    Task<Result> DeleteAsync(int id);
}
