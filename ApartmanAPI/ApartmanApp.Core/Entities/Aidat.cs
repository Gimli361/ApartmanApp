using ApartmanApp.Core.Common;
using ApartmanApp.Core.Enums;

namespace ApartmanApp.Core.Entities;

public class Aidat : IAuditable, ISoftDeletable
{
    public int Id { get; set; }
    public int KullaniciId { get; set; }
    public decimal Tutar { get; set; }
    public int Ay { get; set; }   // 1–12
    public int Yil { get; set; }
    public OdemeDurumu OdemeDurumu { get; set; } = OdemeDurumu.Beklemede;
    public DateTime? OdemeTarihi { get; set; }

    // Audit + Soft delete
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }

    // Navigation
    public Kullanici Kullanici { get; set; } = null!;
}
