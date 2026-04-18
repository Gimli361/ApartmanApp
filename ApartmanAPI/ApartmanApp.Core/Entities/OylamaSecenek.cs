namespace ApartmanApp.Core.Entities;

public class OylamaSecenek
{
    public int Id { get; set; }
    public int OylamaId { get; set; }
    public string Metin { get; set; } = string.Empty;

    // Navigation
    public Oylama? Oylama { get; set; }
    public ICollection<OylamaOyu> Oylar { get; set; } = [];
}
