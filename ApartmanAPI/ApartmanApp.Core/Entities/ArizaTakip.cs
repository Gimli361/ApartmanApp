namespace ApartmanApp.Core.Entities;

public class ArizaTakip
{
    public int Id { get; set; }
    public int ArizaId { get; set; }
    public int KullaniciId { get; set; }
    public DateTime TakipTarihi { get; set; } = DateTime.UtcNow;

    // Navigation
    public Ariza? Ariza { get; set; }
    public Kullanici? Kullanici { get; set; }
}
