using ApartmanApp.Core.Common;

namespace ApartmanApp.Core.Entities;

public class Oylama : IAuditable, ISoftDeletable
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string? Aciklama { get; set; }
    public DateTime BaslangicTarihi { get; set; } = DateTime.UtcNow;
    public DateTime BitisTarihi { get; set; }
    public int OlusturanId { get; set; }
    public bool AktifMi { get; set; } = true;

    // Audit + Soft delete
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }

    // Navigation
    public Kullanici? Olusturan { get; set; }
    public ICollection<OylamaSecenek> Secenekler { get; set; } = [];
    public ICollection<OylamaOyu> Oylar { get; set; } = [];
}
