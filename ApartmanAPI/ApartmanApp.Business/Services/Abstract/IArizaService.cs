using ApartmanApp.Business.DTOs.Ariza;
using ApartmanApp.Core.Common;

namespace ApartmanApp.Business.Services.Abstract;

public interface IArizaService
{
    Task<Result<List<ArizaListDto>>> GetAllAsync(string? blokNo = null);
    Task<Result<PagedResult<ArizaListDto>>> GetPagedAsync(int page, int pageSize, string? blokNo = null);
    Task<Result<ArizaDetailDto>> GetByIdAsync(int id);
    Task<Result<ArizaDetailDto>> CreateAsync(ArizaCreateDto dto);
    Task<Result<ArizaDetailDto>> UpdateDurumAsync(int id, ArizaDurumGuncelleDto dto);
    Task<Result> DeleteAsync(int id);
}
