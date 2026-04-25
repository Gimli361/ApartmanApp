using ApartmanApp.Business.Mappings;
using ApartmanApp.Data.Context;
using ApartmanApp.Data.Interceptors;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

namespace ApartmanApp.Tests.TestHelpers;

/// Test'ler için InMemory DB + AutoMapper + IConfiguration üretir.
public static class TestDb
{
    /// Her test için izole bir AppDbContext (interceptor'lı).
    public static AppDbContext CreateDbContext(string? dbName = null)
    {
        var name = dbName ?? Guid.NewGuid().ToString();
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(name)
            .AddInterceptors(new AuditSaveChangesInterceptor())
            .Options;
        return new AppDbContext(options);
    }

    public static IMapper CreateMapper()
    {
        // AutoMapper 15+ MapperConfiguration ctor'ı ILoggerFactory bekler
        var cfg = new MapperConfiguration(
            c => c.AddProfile<MappingProfile>(),
            NullLoggerFactory.Instance);
        return cfg.CreateMapper();
    }

    public static IConfiguration CreateConfig(Dictionary<string, string?>? overrides = null)
    {
        var defaults = new Dictionary<string, string?>
        {
            ["Jwt:Key"] = "TEST_SECRET_KEY_AT_LEAST_32_BYTES_LONG_FOR_HMAC256!!",
            ["Jwt:Issuer"] = "TestIssuer",
            ["Jwt:Audience"] = "TestAudience",
            ["Jwt:ExpiryMinutes"] = "60",
        };
        if (overrides is not null)
            foreach (var kv in overrides) defaults[kv.Key] = kv.Value;
        return new ConfigurationBuilder()
            .AddInMemoryCollection(defaults)
            .Build();
    }
}
