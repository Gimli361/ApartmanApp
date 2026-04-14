using ApartmanApp.Core.Enums;

namespace ApartmanApp.Core.Entities;

public class Aidat
{
    public int Id { get; set; }
    public int KullaniciId { get; set; }
    public decimal Tutar { get; set; }
    public int Ay { get; set; }   // 1–12
    public int Yil { get; set; }
    public OdemeDurumu OdemeDurumu { get; set; } = OdemeDurumu.Beklemede;
    public DateTime? OdemeTarihi { get; set; }

    // Navigation
    public Kullanici Kullanici { get; set; } = null!;
}
