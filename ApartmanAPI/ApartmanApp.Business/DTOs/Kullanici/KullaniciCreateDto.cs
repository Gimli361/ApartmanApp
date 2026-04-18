using ApartmanApp.Core.Enums;

namespace ApartmanApp.Business.DTOs.Kullanici;

public class KullaniciCreateDto
{
    public string Ad { get; set; } = string.Empty;
    public string Soyad { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public KullaniciRol Rol { get; set; } = KullaniciRol.Sakin;
    public string DaireNo { get; set; } = string.Empty;
    public string? BlokNo { get; set; }
    public string Sifre { get; set; } = string.Empty;
}
