using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;
using ApartmanApp.Data.Configurations;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Data.Context;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Kullanici> Kullanicilar => Set<Kullanici>();
    public DbSet<Blok> Bloklar => Set<Blok>();
    public DbSet<Daire> Daireler => Set<Daire>();
    public DbSet<Ariza> Arizalar => Set<Ariza>();
    public DbSet<ArizaFoto> ArizaFotolar => Set<ArizaFoto>();
    public DbSet<Bildirim> Bildirimler => Set<Bildirim>();
    public DbSet<Aidat> Aidatlar => Set<Aidat>();
    public DbSet<OtomatikAidat> OtomatikAidatlar => Set<OtomatikAidat>();
    public DbSet<ArizaTakip> ArizaTakipler => Set<ArizaTakip>();
    public DbSet<Oylama> Oylamalar => Set<Oylama>();
    public DbSet<OylamaSecenek> OylamaSecenekler => Set<OylamaSecenek>();
    public DbSet<OylamaOyu> OylamaOylari => Set<OylamaOyu>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new KullaniciConfiguration());
        modelBuilder.ApplyConfiguration(new ArizaConfiguration());
        modelBuilder.ApplyConfiguration(new ArizaFotoConfiguration());
        modelBuilder.ApplyConfiguration(new BildirimConfiguration());
        modelBuilder.ApplyConfiguration(new AidatConfiguration());
        modelBuilder.ApplyConfiguration(new OtomatikAidatConfiguration());
        modelBuilder.ApplyConfiguration(new ArizaTakipConfiguration());
        modelBuilder.ApplyConfiguration(new OylamaConfiguration());
        modelBuilder.ApplyConfiguration(new OylamaSecenekConfiguration());
        modelBuilder.ApplyConfiguration(new OylamaOyuConfiguration());
        modelBuilder.ApplyConfiguration(new RefreshTokenConfiguration());

        // Global query filter — soft-deleted kayıtlar varsayılan sorgularda gizlenir.
        // ISoftDeletable implement eden tüm entity'lere otomatik uygulanır.
        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            if (typeof(ISoftDeletable).IsAssignableFrom(entityType.ClrType))
            {
                var param = System.Linq.Expressions.Expression.Parameter(entityType.ClrType, "e");
                var prop = System.Linq.Expressions.Expression.Property(param, nameof(ISoftDeletable.IsDeleted));
                var notDeleted = System.Linq.Expressions.Expression.Not(prop);
                var lambda = System.Linq.Expressions.Expression.Lambda(notDeleted, param);
                modelBuilder.Entity(entityType.ClrType).HasQueryFilter(lambda);
            }
        }

        base.OnModelCreating(modelBuilder);
    }
}
