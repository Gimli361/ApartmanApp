using System.ComponentModel.DataAnnotations;

namespace ApartmanWeb.Models;

public class AidatDto
{
    public int Id { get; set; }
    public int KullaniciId { get; set; }
    public string? KullaniciAdSoyad { get; set; }
    public string? DaireNo { get; set; }
    public decimal Tutar { get; set; }
    public int Ay { get; set; }
    public int Yil { get; set; }
    public string OdemeDurumu { get; set; } = "Beklemede";
}

public class AidatCreateRequest
{
    [Required]
    public int KullaniciId { get; set; }
    [Required]
    public decimal Tutar { get; set; }
    [Required]
    public int Ay { get; set; }
    [Required]
    public int Yil { get; set; }
}

public class OtomatikAidatDto
{
    public int Id { get; set; }
    public int KullaniciId { get; set; }
    public string? KullaniciAdSoyad { get; set; }
    public string? DaireNo { get; set; }
    public decimal Tutar { get; set; }
    public bool AktifMi { get; set; }
}

public class OtomatikAidatCreateRequest
{
    [Required]
    public int KullaniciId { get; set; }
    [Required]
    public decimal Tutar { get; set; }
    public bool AktifMi { get; set; } = true;
}

public class AidatViewModel
{
    public List<AidatDto> Aidatlar { get; set; } = new();
    public List<OtomatikAidatDto> OtomatikAidatlar { get; set; } = new();
    public List<KullaniciDto> Kullanicilar { get; set; } = new();
}
