namespace ApartmanApp.Core.Entities;

public class ArizaFoto
{
    public int Id { get; set; }
    public int ArizaId { get; set; }
    public string DosyaAdi { get; set; } = string.Empty;
    public string DosyaYolu { get; set; } = string.Empty;
    public long DosyaBoyutu { get; set; }
    public DateTime YuklemeTarihi { get; set; } = DateTime.UtcNow;

    // Navigation
    public Ariza? Ariza { get; set; }
}
