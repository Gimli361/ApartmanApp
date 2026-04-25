using ApartmanApp.Core.Common;
using ApartmanApp.Core.Enums;

namespace ApartmanApp.Core.Entities;

public class Ariza : IAuditable, ISoftDeletable
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string Aciklama { get; set; } = string.Empty;
    public ArizaDurum Durum { get; set; } = ArizaDurum.Beklemede;
    public ArizaOncelik Oncelik { get; set; } = ArizaOncelik.Orta;
    public int BildirenId { get; set; }
    public DateTime Tarih { get; set; } = DateTime.UtcNow;
    public string? BlokNo { get; set; }
    public string? RedNedeni { get; set; }

    // Audit + Soft delete
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }

    // Navigation
    public Kullanici? Bildiren { get; set; }
    public ICollection<ArizaFoto> Fotograflar { get; set; } = [];
    public ICollection<ArizaTakip> Takipler { get; set; } = [];
}
