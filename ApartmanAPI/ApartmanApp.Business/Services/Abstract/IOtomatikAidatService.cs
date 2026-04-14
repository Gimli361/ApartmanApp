using ApartmanApp.Business.DTOs.Aidat;
using ApartmanApp.Core.Common;

namespace ApartmanApp.Business.Services.Abstract;

public interface IOtomatikAidatService
{
    /// Tüm otomatik aidat konfigürasyonlarını listele
    Task<Result<List<OtomatikAidatDto>>> GetAllAsync();

    /// Kullanıcı için otomatik aidat oluştur veya güncelle
    Task<Result<OtomatikAidatDto>> UpsertAsync(OtomatikAidatUpsertDto dto);

    /// Aktif/pasif geçiş
    Task<Result<OtomatikAidatDto>> ToggleAktifAsync(int id);

    /// Tutar güncelle
    Task<Result<OtomatikAidatDto>> UpdateTutarAsync(int id, OtomatikAidatTutarGuncelleDto dto);

    /// Sil
    Task<Result> DeleteAsync(int id);

    /// Verilen ay/yıl için aktif konfigürasyonlardan eksik aidatları oluştur.
    /// Kaç kayıt oluşturulduğunu döndürür.
    Task<int> UretAylikAidatlarAsync(int ay, int yil);
}
