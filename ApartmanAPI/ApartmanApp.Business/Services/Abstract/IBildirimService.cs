using ApartmanApp.Business.DTOs.Bildirim;
using ApartmanApp.Core.Common;

namespace ApartmanApp.Business.Services.Abstract;

public interface IBildirimService
{
    Task<Result<List<BildirimListDto>>> GetByKullaniciIdAsync(int kullaniciId);
    Task<Result<PagedResult<BildirimListDto>>> GetPagedByKullaniciIdAsync(int kullaniciId, int page, int pageSize);
    Task<int> GetUnreadCountAsync(int kullaniciId);
    Task<Result> MarkAsReadAsync(int bildirimId, int kullaniciId);
    Task<Result> MarkAllAsReadAsync(int kullaniciId);

    /// Belirli bir kullanıcıya bildirim gönder + DB'ye kaydet
    Task SendToKullaniciAsync(int aliciId, string baslik, string icerik, string tip);

    /// Tüm sakinlere duyuru gönder + DB'ye kaydet
    Task SendToAllSakinlerAsync(string baslik, string icerik);

    /// Belirli bloktaki tüm sakinlere bildirim gönder + DB'ye kaydet
    Task SendToBlokAsync(string blokNo, string baslik, string icerik);

    /// Belirli dairedeki kullanıcılara bildirim gönder + DB'ye kaydet (blokNo opsiyonel)
    Task SendToDaireAsync(string daireNo, string baslik, string icerik, string? blokNo = null);

    /// Tüm adminlere bildirim gönder + DB'ye kaydet
    Task SendToAdminlerAsync(string baslik, string icerik, string tip);

    /// Bir arızayı takip eden tüm kullanıcılara bildirim gönder + DB'ye kaydet
    /// excludeKullaniciId: bu kullanıcıya takipçi bildirimi gönderme (bildiren zaten ayrıca alıyor)
    Task SendToTakipcilerAsync(int arizaId, string baslik, string icerik, string tip, int? excludeKullaniciId = null);
}
