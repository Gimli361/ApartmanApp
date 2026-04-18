using ApartmanApp.Business.DTOs.Kullanici;
using ApartmanApp.Core.Common;

namespace ApartmanApp.Business.Services.Abstract;

public interface IKullaniciService
{
    Task<Result<List<KullaniciListDto>>> GetAllAsync();
    Task<Result<KullaniciListDto>> GetByIdAsync(int id);
    Task<Result<KullaniciListDto>> CreateAsync(KullaniciCreateDto dto);
    Task<Result<KullaniciListDto>> UpdateAsync(int id, KullaniciUpdateDto dto);
    Task<Result> UpdateSifreAsync(int id, SifreGuncelleDto dto);
    Task<Result> AdminSifreSifirlaAsync(int id, string yeniSifre);
    Task<Result> DeleteAsync(int id);
    Task<Result> UpdateFcmTokenAsync(int id, string token);
}
