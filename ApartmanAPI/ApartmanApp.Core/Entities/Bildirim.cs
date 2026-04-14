namespace ApartmanApp.Core.Entities;

public class Bildirim
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string Icerik { get; set; } = string.Empty;
    public string Tip { get; set; } = string.Empty; // "ArizaDurum" | "YeniAriza" | "Duyuru" | "DaireMesaj"
    public int? AliciId { get; set; }               // null = sistem bildirimi (admin'e gönderilir)
    public DateTime GonderimTarihi { get; set; }
    public bool Okundu { get; set; }

    // Navigation
    public Kullanici? Alici { get; set; }
}
