using ApartmanApp.Business.DTOs.Kullanici;

namespace ApartmanApp.Business.DTOs.Auth;

public class TokenResponseDto
{
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public KullaniciListDto User { get; set; } = null!;
}
