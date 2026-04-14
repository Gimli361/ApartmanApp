using ApartmanApp.Core.Enums;

namespace ApartmanApp.Business.DTOs.Aidat;

public class AidatListDto
{
    public int Id { get; set; }
    public int KullaniciId { get; set; }
    public string KullaniciAdSoyad { get; set; } = string.Empty;
    public string DaireNo { get; set; } = string.Empty;
    public decimal Tutar { get; set; }
    public int Ay { get; set; }
    public int Yil { get; set; }
    public OdemeDurumu OdemeDurumu { get; set; }
    public DateTime? OdemeTarihi { get; set; }
}
