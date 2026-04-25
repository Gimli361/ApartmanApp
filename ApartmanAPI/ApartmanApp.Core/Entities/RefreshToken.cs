namespace ApartmanApp.Core.Entities;

/// Refresh token — kısa ömürlü JWT'yi tazelemek için.
/// Rotation pattern: her kullanım sonrası eski token revoke edilip yenisi üretilir.
public class RefreshToken
{
    public int Id { get; set; }
    public string Token { get; set; } = string.Empty;
    public int KullaniciId { get; set; }
    public Kullanici? Kullanici { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }

    /// Replay korunması — eğer revoke edilmiş bir token tekrar kullanılırsa
    /// tüm chain revoke edilmelidir.
    public string? ReplacedByToken { get; set; }

    public bool IsActive => RevokedAt is null && DateTime.UtcNow < ExpiresAt;
}
