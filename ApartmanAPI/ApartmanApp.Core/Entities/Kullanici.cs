using ApartmanApp.Core.Enums;

namespace ApartmanApp.Core.Entities;

public class Kullanici
{
    public int Id { get; set; }
    public string Ad { get; set; } = string.Empty;
    public string Soyad { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public KullaniciRol Rol { get; set; }
    public string DaireNo { get; set; } = string.Empty;
    public string? FcmToken { get; set; }
    public string SifreHash { get; set; } = string.Empty;
    public string? BlokNo { get; set; }

    // Navigation
    public ICollection<Ariza> Arizalar { get; set; } = [];
    public ICollection<ArizaTakip> Takipler { get; set; } = [];
}
