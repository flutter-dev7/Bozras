using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Bozras.Application.Common;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;
using Bozras.Infrastructure.Persistence.Data;

namespace Bozras.Infrastructure.Persistence.Seeds;

public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();
        var passwords = scope.ServiceProvider.GetRequiredService<IPasswordService>();

        await LocationSeeder.SeedAsync(context);
        await SeedSuperAdminAsync(context, configuration, passwords);
    }

    private static async Task SeedSuperAdminAsync(
        AppDbContext context, IConfiguration configuration, IPasswordService passwords)
    {
        if (await context.Users.AnyAsync(u => u.Role == UserRole.SuperAdmin))
            return;

        var email = EmailNormalizer.Normalize(configuration["Seed:SuperAdminEmail"]);
        if (email is null)
            return;

        if (await context.Users.AnyAsync(u => u.Email == email))
            return;

        var phone = PhoneNumberNormalizer.Normalize(configuration["Seed:SuperAdminPhone"])
            ?? throw new InvalidOperationException("Задайте Seed:SuperAdminPhone.");

        var password = configuration["Seed:SuperAdminPassword"];
        if (!string.IsNullOrEmpty(password))
        {
            var passwordError = PasswordRules.Validate(password);
            if (passwordError is not null)
                throw new InvalidOperationException($"Seed:SuperAdminPassword: {passwordError}");
        }

        context.Users.Add(new User
        {
            FirstName = configuration["Seed:SuperAdminFirstName"] ?? "Super",
            LastName = configuration["Seed:SuperAdminLastName"] ?? "Admin",
            Phone = phone,
            Email = email,
            EmailConfirmed = true,
            Role = UserRole.SuperAdmin,
            IsActive = true,
            PasswordHash = string.IsNullOrEmpty(password) ? null : passwords.Hash(password)
        });

        await context.SaveChangesAsync();
    }
}