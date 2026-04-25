using ApartmanApp.Core.Common;

namespace ApartmanApp.Core.Entities;

public class Bildirim : IAuditable, ISoftDeletable
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string Icerik { get; set; } = string.Empty;
    public string Tip { get; set; } = string.Empty; // "ArizaDurum" | "YeniAriza" | "Duyuru" | "DaireMesaj"
    public int? AliciId { get; set; }               // null = sistem bildirimi (admin'e gönderilir)
    public DateTime GonderimTarihi { get; set; }
    public bool Okundu { get; set; }

    // Audit + Soft delete
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }

    // Navigation
    public Kullanici? Alici { get; set; }
}
