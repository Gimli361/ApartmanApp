using ApartmanApp.Business.DTOs.Ariza;
using ApartmanApp.Core.Common;

namespace ApartmanApp.Business.Services.Abstract;

public interface IArizaTakipService
{
    Task<Result> TakipEtAsync(int arizaId, int kullaniciId);
    Task<Result> TakiptenCikAsync(int arizaId, int kullaniciId);
    Task<TakipDurumuDto> GetTakipDurumuAsync(int arizaId, int kullaniciId);
}
