using ApartmanApp.Core.Entities;
using ApartmanApp.Data.Configurations;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Data.Context;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Kullanici> Kullanicilar => Set<Kullanici>();
    public DbSet<Ariza> Arizalar => Set<Ariza>();
    public DbSet<ArizaFoto> ArizaFotolar => Set<ArizaFoto>();
    public DbSet<Bildirim> Bildirimler => Set<Bildirim>();
    public DbSet<Aidat> Aidatlar => Set<Aidat>();
    public DbSet<OtomatikAidat> OtomatikAidatlar => Set<OtomatikAidat>();
    public DbSet<ArizaTakip> ArizaTakipler => Set<ArizaTakip>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new KullaniciConfiguration());
        modelBuilder.ApplyConfiguration(new ArizaConfiguration());
        modelBuilder.ApplyConfiguration(new ArizaFotoConfiguration());
        modelBuilder.ApplyConfiguration(new BildirimConfiguration());
        modelBuilder.ApplyConfiguration(new AidatConfiguration());
        modelBuilder.ApplyConfiguration(new OtomatikAidatConfiguration());
        modelBuilder.ApplyConfiguration(new ArizaTakipConfiguration());
        base.OnModelCreating(modelBuilder);
    }
}
