using Microsoft.EntityFrameworkCore;
using Non.Domain.Entities;
using Non.Domain.Enums;
using Non.Infrastructure.Persistence.Data;

namespace Non.Infrastructure.Persistence.Seeds;

public static class LocationSeeder
{
    public static async Task SeedAsync(AppDbContext context, CancellationToken ct = default)
    {
        if (await context.Locations.AnyAsync(ct))
            return;

        Location Node(string name, LocationType type, params Location[] children) => new()
        {
            Name = name,
            Type = type,
            Children = children.ToList()
        };

        Location City(string name) => Node(name, LocationType.City);
        Location District(string name) => Node(name, LocationType.District);

        var items = new[]
        {
            Node("Душанбе", LocationType.City,
                District("Сино"), District("Фирдавси"), District("Шохмансур"), District("Исмоили Сомони")),

            Node("Согдийская область", LocationType.Region,
                City("Худжанд"), City("Истаравшан"), City("Исфара"), City("Канибадам"),
                City("Панджакент"), City("Гафуров"), City("Бустон")),

            Node("Хатлонская область", LocationType.Region,
                City("Бохтар"), City("Куляб"), City("Нурек"), City("Левакант")),

            Node("Районы республиканского подчинения", LocationType.Region,
                City("Вахдат"), City("Хисор"), City("Турсунзода"), District("Рудаки")),

            Node("ГБАО", LocationType.Region, City("Хорог"))
        };

        await context.Locations.AddRangeAsync(items, ct);
        await context.SaveChangesAsync(ct);
    }
}