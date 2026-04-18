namespace ApartmanApp.Core.Entities;

public class OylamaOyu
{
    public int Id { get; set; }
    public int OylamaId { get; set; }
    public int SecenekId { get; set; }
    public int KullaniciId { get; set; }
    public DateTime OyTarihi { get; set; } = DateTime.UtcNow;

    // Navigation
    public Oylama? Oylama { get; set; }
    public OylamaSecenek? Secenek { get; set; }
    public Kullanici? Kullanici { get; set; }
}
