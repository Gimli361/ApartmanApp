using System.ComponentModel.DataAnnotations;

namespace ApartmanWeb.Models;

public class KullaniciDto
{
    public int Id { get; set; }
    public string AdSoyad { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string? DaireNo { get; set; }
}

public class KullaniciCreateRequest
{
    [Required(ErrorMessage = "Ad zorunludur")]
    public string Ad { get; set; } = string.Empty;

    [Required(ErrorMessage = "Soyad zorunludur")]
    public string Soyad { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email zorunludur")]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Sifre zorunludur")]
    public string Sifre { get; set; } = string.Empty;

    [Required(ErrorMessage = "Rol zorunludur")]
    public string Rol { get; set; } = "Sakin";

    public string? DaireNo { get; set; }
}

public class KullaniciUpdateRequest
{
    [Required(ErrorMessage = "Ad zorunludur")]
    public string Ad { get; set; } = string.Empty;

    [Required(ErrorMessage = "Soyad zorunludur")]
    public string Soyad { get; set; } = string.Empty;

    public string? DaireNo { get; set; }
}

public class KullaniciListResponse
{
    public bool Success { get; set; }
    public List<KullaniciDto> Data { get; set; } = new();
}

public class KullaniciSingleResponse
{
    public bool Success { get; set; }
    public KullaniciDto? Data { get; set; }
}

public class ProfilUpdateRequest
{
    [Required(ErrorMessage = "Ad zorunludur")]
    public string Ad { get; set; } = string.Empty;

    [Required(ErrorMessage = "Soyad zorunludur")]
    public string Soyad { get; set; } = string.Empty;

    public string DaireNo { get; set; } = string.Empty;
    public string? BlokNo { get; set; }
}

public class SifreGuncelleRequest
{
    [Required(ErrorMessage = "Eski şifre zorunludur")]
    public string EskiSifre { get; set; } = string.Empty;

    [Required(ErrorMessage = "Yeni şifre zorunludur")]
    [MinLength(8, ErrorMessage = "Şifre en az 8 karakter olmalıdır")]
    public string YeniSifre { get; set; } = string.Empty;
}
