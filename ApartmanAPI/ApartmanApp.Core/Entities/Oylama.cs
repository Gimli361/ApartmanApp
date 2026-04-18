namespace ApartmanApp.Core.Entities;

public class Oylama
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string? Aciklama { get; set; }
    public DateTime BaslangicTarihi { get; set; } = DateTime.UtcNow;
    public DateTime BitisTarihi { get; set; }
    public int OlusturanId { get; set; }
    public bool AktifMi { get; set; } = true;

    // Navigation
    public Kullanici? Olusturan { get; set; }
    public ICollection<OylamaSecenek> Secenekler { get; set; } = [];
    public ICollection<OylamaOyu> Oylar { get; set; } = [];
}
