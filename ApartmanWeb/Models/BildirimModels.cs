using System.ComponentModel.DataAnnotations;

namespace ApartmanWeb.Models;

public class BildirimDto
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string Icerik { get; set; } = string.Empty;
    public DateTime GonderimTarihi { get; set; }
    public bool Okundu { get; set; }
    public string? Tip { get; set; }
}

public class DuyuruRequest
{
    [Required(ErrorMessage = "Baslik zorunludur")]
    public string Baslik { get; set; } = string.Empty;
    [Required(ErrorMessage = "Icerik zorunludur")]
    public string Icerik { get; set; } = string.Empty;
}

public class BlokBildirimRequest
{
    [Required(ErrorMessage = "Blok No zorunludur")]
    public string BlokNo { get; set; } = string.Empty;
    [Required(ErrorMessage = "Baslik zorunludur")]
    public string Baslik { get; set; } = string.Empty;
    [Required(ErrorMessage = "Icerik zorunludur")]
    public string Icerik { get; set; } = string.Empty;
}

public class DaireBildirimRequest
{
    public string? BlokNo { get; set; }
    [Required(ErrorMessage = "Daire No zorunludur")]
    public string DaireNo { get; set; } = string.Empty;
    [Required(ErrorMessage = "Baslik zorunludur")]
    public string Baslik { get; set; } = string.Empty;
    [Required(ErrorMessage = "Icerik zorunludur")]
    public string Icerik { get; set; } = string.Empty;
}
