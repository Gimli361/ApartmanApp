namespace ApartmanApp.Business.DTOs.Kullanici;

public class KullaniciUpdateDto
{
    public string Ad { get; set; } = string.Empty;
    public string Soyad { get; set; } = string.Empty;
    public string DaireNo { get; set; } = string.Empty;
    public string? BlokNo { get; set; }
}
