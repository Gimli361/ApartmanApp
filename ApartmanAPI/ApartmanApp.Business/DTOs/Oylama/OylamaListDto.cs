namespace ApartmanApp.Business.DTOs.Oylama;

public class OylamaListDto
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string? Aciklama { get; set; }
    public DateTime BaslangicTarihi { get; set; }
    public DateTime BitisTarihi { get; set; }
    public bool AktifMi { get; set; }
    public int ToplamOySayisi { get; set; }
    public bool KullaniciOyKullandi { get; set; }
}
