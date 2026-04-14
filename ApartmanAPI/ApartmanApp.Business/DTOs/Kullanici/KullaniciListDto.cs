using ApartmanApp.Core.Enums;

namespace ApartmanApp.Business.DTOs.Kullanici;

public class KullaniciListDto
{
    public int Id { get; set; }
    public string AdSoyad { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public KullaniciRol Rol { get; set; }
    public string DaireNo { get; set; } = string.Empty;
    public string? BlokNo { get; set; }
}
