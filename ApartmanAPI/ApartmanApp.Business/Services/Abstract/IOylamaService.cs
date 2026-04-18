using ApartmanApp.Business.DTOs.Oylama;
using ApartmanApp.Core.Common;

namespace ApartmanApp.Business.Services.Abstract;

public interface IOylamaService
{
    Task<Result<List<OylamaListDto>>> GetAllAsync(int kullaniciId);
    Task<Result<OylamaDetailDto>> GetByIdAsync(int id, int kullaniciId);
    Task<Result<OylamaDetailDto>> CreateAsync(OylamaCreateDto dto, int olusturanId);
    Task<Result> OyVerAsync(int oylamaId, int secenekId, int kullaniciId);
    Task<Result> OyGeriAlAsync(int oylamaId, int kullaniciId);
    Task<Result> DeleteAsync(int id);
    Task<Result> ToggleAktifAsync(int id);
}
