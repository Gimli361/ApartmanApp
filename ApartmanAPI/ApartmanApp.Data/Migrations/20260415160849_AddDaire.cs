using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ApartmanApp.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddDaire : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // AddBlok migration boş kaldığından Bloklar tablosunu burada oluşturuyoruz.
            migrationBuilder.CreateTable(
                name: "Bloklar",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Ad = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Bloklar", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Daireler",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    BlokId = table.Column<int>(type: "integer", nullable: false),
                    DaireNo = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Daireler", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Daireler_Bloklar_BlokId",
                        column: x => x.BlokId,
                        principalTable: "Bloklar",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Daireler_BlokId",
                table: "Daireler",
                column: "BlokId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Daireler");

            migrationBuilder.DropTable(
                name: "Bloklar");
        }
    }
}
