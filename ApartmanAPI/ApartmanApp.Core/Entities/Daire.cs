namespace ApartmanApp.Core.Entities;

public class Daire
{
    public int Id { get; set; }
    public int BlokId { get; set; }
    public Blok Blok { get; set; } = null!;

    /// <summary>Daire numarası — örn. "1", "2A", "12"</summary>
    public string DaireNo { get; set; } = string.Empty;
}
