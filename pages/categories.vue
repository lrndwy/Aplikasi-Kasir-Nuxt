<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-2 sm:p-4">
    <h1 class="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-gray-900 dark:text-white">
      Manajemen Kategori Produk
    </h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div
      v-else-if="!hasAdminOrManagerRole"
      class="text-center text-red-500 dark:text-red-400"
    >
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else>
      <div class="mb-6 flex justify-end">
        <Dialog :open="isCategoryFormOpen" @update:open="isCategoryFormOpen = $event">
          <DialogTrigger as-child>
            <Button @click="addNewCategory">Tambah Kategori Baru</Button>
          </DialogTrigger>
          <DialogContent class="sm:max-w-[600px] p-6 max-h-[80vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>{{
                isEditing ? "Edit Kategori" : "Tambah Kategori Baru"
              }}</DialogTitle>
              <DialogDescription>
                {{
                  isEditing
                    ? "Perbarui detail kategori."
                    : "Tambahkan kategori baru ke daftar."
                }}
              </DialogDescription>
            </DialogHeader>
            <form @submit.prevent="saveCategory" class="space-y-4 py-4">
              <div>
                <Label for="categoryName" class="mb-2">Nama Kategori</Label>
                <Input
                  id="categoryName"
                  v-model="categoryForm.name"
                  type="text"
                  placeholder="Nama Kategori"
                  required
                />
              </div>
              <div>
                <Label for="categoryDescription" class="mb-2">Deskripsi</Label>
                <Textarea
                  id="categoryDescription"
                  v-model="categoryForm.description"
                  placeholder="Deskripsi Kategori"
                />
              </div>
              <div class="flex items-center space-x-2">
                <Checkbox id="isActive" v-model="categoryForm.is_active" />
                <Label for="isActive">Aktif</Label>
              </div>
              <DialogFooter class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2 pt-4">
                <DialogClose as-child>
                  <Button type="button" variant="outline" @click="cancelEdit"
                    class="w-full sm:w-auto mb-2 sm:mb-0"
                    >Batal</Button
                  >
                </DialogClose>
                <Button
                  v-if="isEditing"
                  type="button"
                  variant="destructive"
                  @click="confirmDeleteCategory(categoryForm.id)"
                  :disabled="loading"
                  class="w-full sm:w-auto mb-2 sm:mb-0"
                >
                  Hapus Kategori
                </Button>
                <Button type="submit" :disabled="loading" class="w-full sm:w-auto">
                  <span v-if="loading">Menyimpan...</span>
                  <span v-else>{{
                    isEditing ? "Perbarui Kategori" : "Tambah Kategori"
                  }}</span>
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <!-- Daftar Kategori -->
      <Card>
        <CardHeader>
          <CardTitle>Daftar Kategori</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead class="min-w-[150px]">Nama</TableHead>
                  <TableHead class="min-w-[200px] hidden md:table-cell">Deskripsi</TableHead>
                  <TableHead class="min-w-[80px]">Aktif</TableHead>
                  <TableHead class="min-w-[150px] hidden md:table-cell">Dibuat Pada</TableHead>
                  <TableHead class="min-w-[150px] hidden md:table-cell">Diperbarui Pada</TableHead>
                  <TableHead class="min-w-[150px]">Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableRow v-for="category in categories" :key="category.id" @click="showCategoryDetail(category)" class="cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700">
                  <TableCell>{{ category.name }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ category.description }}</TableCell>
                  <TableCell>
                    <Badge :variant="category.is_active ? 'success' : 'destructive'">
                      {{ category.is_active ? "Aktif" : "Tidak Aktif" }}
                    </Badge>
                  </TableCell>
                  <TableCell class="hidden md:table-cell">{{ formatDate(category.created_at) }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ formatDate(category.updated_at) }}</TableCell>
                  <TableCell @click.stop>
                    <DropdownMenu>
                      <DropdownMenuTrigger as-child>
                        <Button variant="ghost" class="h-8 w-8 p-0">
                          <span class="sr-only">Open menu</span>
                          <MoreHorizontal class="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuLabel>Aksi</DropdownMenuLabel>
                        <DropdownMenuItem @click="showCategoryDetail(category)">
                          <Info class="mr-2 h-4 w-4" />Detail
                        </DropdownMenuItem>
                        <DropdownMenuItem @click="editCategory(category)">
                          <Edit class="mr-2 h-4 w-4" />Edit
                        </DropdownMenuItem>
                        <DropdownMenuItem @click="confirmDeleteCategory(category.id)">
                          <Trash2 class="mr-2 h-4 w-4" />Hapus
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </div>
          <div
            v-if="categories.length === 0 && !loading"
            class="text-center text-gray-500 dark:text-gray-400 mt-4"
          >
            Tidak ada kategori ditemukan.
          </div>
        </CardContent>
      </Card>

      <!-- Delete Confirmation Dialog -->
      <Dialog :open="isConfirmDeleteOpen" @update:open="isConfirmDeleteOpen = $event">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Konfirmasi Hapus Kategori</DialogTitle>
            <DialogDescription>
              Apakah Anda yakin ingin menghapus kategori ini? Tindakan ini tidak dapat
              dibatalkan.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" @click="isConfirmDeleteOpen = false">Batal</Button>
            <Button
              variant="destructive"
              @click="deleteCategoryConfirmed"
              :disabled="loading"
            >
              <span v-if="loading">Menghapus...</span>
              <span v-else>Hapus</span>
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <!-- Category Detail Dialog -->
      <Dialog :open="isCategoryDetailOpen" @update:open="isCategoryDetailOpen = $event">
        <DialogContent class="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Detail Kategori</DialogTitle>
            <DialogDescription>Informasi lengkap mengenai kategori ini.</DialogDescription>
          </DialogHeader>
          <div v-if="selectedCategory" class="grid gap-4 py-4">
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailName" class="text-right">Nama</Label>
              <Input id="detailName" :model-value="selectedCategory.name" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailDescription" class="text-right">Deskripsi</Label>
              <Textarea id="detailDescription" :model-value="selectedCategory.description || 'Tidak ada deskripsi'" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailIsActive" class="text-right">Aktif</Label>
              <div class="col-span-3">
                <Badge :variant="selectedCategory.is_active ? 'success' : 'destructive'">
                  {{ selectedCategory.is_active ? "Aktif" : "Tidak Aktif" }}
                </Badge>
              </div>
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailCreatedAt" class="text-right">Dibuat Pada</Label>
              <Input id="detailCreatedAt" :model-value="formatDate(selectedCategory.created_at)" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailUpdatedAt" class="text-right">Diperbarui Pada</Label>
              <Input id="detailUpdatedAt" :model-value="formatDate(selectedCategory.updated_at)" readonly class="col-span-3" />
            </div>
          </div>
          <DialogFooter>
            <DialogClose as-child>
              <Button type="button" variant="outline">Tutup</Button>
            </DialogClose>
            <Button @click="editCategory(selectedCategory!)">
              <Edit class="mr-2 h-4 w-4" />Edit Kategori
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
    <Toaster />
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Categories - Aplikasi Kasir'
})
import { ref, onMounted, watch } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { toast } from 'vue-sonner';
import { Toaster } from '@/components/ui/sonner';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import 'vue-sonner/style.css'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogClose,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreHorizontal, Edit, Trash2, Info } from "lucide-vue-next";

interface Category {
  id: string;
  name: string;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const categories = ref<Category[]>([]);
const categoryForm = ref({
  id: "",
  name: "",
  description: "",
  is_active: true,
});
const pageLoading = ref(true); // New ref for overall page loading
const isEditing = ref(false);
const loading = ref(false);
const hasAdminOrManagerRole = ref(false);
const isCategoryFormOpen = ref(false); // Controls the add/edit category dialog
const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog
const categoryToDeleteId = ref<string | null>(null); // Stores the ID of the category to be deleted
const isCategoryDetailOpen = ref(false); // Controls the category detail dialog
const selectedCategory = ref<Category | null>(null); // Stores the selected category for detail view

const fetchCategories = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from("categories")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;
    categories.value = data as Category[];
  } catch (error: any) {
    toast.error("Gagal memuat kategori!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const checkUserRole = async () => {
  if (!user.value) {
    hasAdminOrManagerRole.value = false;
    return;
  }
  const { data, error } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.value.id)
    .single();

  if (error) {
    toast.error("Gagal memeriksa peran pengguna!", {
      description: error.message,
    });
    hasAdminOrManagerRole.value = false;
    return;
  }
  if (!data) {
    toast.error("Data profil pengguna tidak ditemukan.");
    hasAdminOrManagerRole.value = false;
    return;
  }
  hasAdminOrManagerRole.value = data?.role === "admin" || data?.role === "manager";
  if (!hasAdminOrManagerRole.value) {
    toast.warning("Anda tidak memiliki izin untuk mengakses halaman ini.", {
      description: "Silakan hubungi administrator untuk mendapatkan akses.",
    });
  }
};

const saveCategory = async () => {
  loading.value = true;
  try {
    if (isEditing.value) {
      const { error } = await supabase
        .from("categories")
        .update({
          name: categoryForm.value.name,
          description: categoryForm.value.description,
          is_active: categoryForm.value.is_active,
          updated_at: new Date().toISOString(),
        })
        .eq("id", categoryForm.value.id);
      if (error) throw error;
      toast.success("Kategori berhasil diperbarui!", {
        description: `Kategori ${categoryForm.value.name} telah berhasil diperbarui.`,
      });
    } else {
      const { error } = await supabase.from("categories").insert({
        name: categoryForm.value.name,
        description: categoryForm.value.description,
        is_active: categoryForm.value.is_active,
      });
      if (error) throw error;
      toast.success("Kategori berhasil ditambahkan!", {
        description: `Kategori ${categoryForm.value.name} telah berhasil ditambahkan.`,
      });
    }
    resetForm();
    await fetchCategories();
    isCategoryFormOpen.value = false; // Close the dialog on success
  } catch (error: any) {
    toast.error("Gagal menyimpan kategori!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const addNewCategory = () => {
  resetForm();
  isCategoryFormOpen.value = true;
};

const editCategory = (category: Category) => {
  isEditing.value = true;
  categoryForm.value = { ...category };
  isCategoryFormOpen.value = true; // Open the dialog for editing
  isCategoryDetailOpen.value = false; // Close detail dialog if open
};

const showCategoryDetail = (category: Category) => {
  selectedCategory.value = category;
  isCategoryDetailOpen.value = true;
};

const cancelEdit = () => {
  resetForm();
  isCategoryFormOpen.value = false; // Close the dialog on cancel
};

const confirmDeleteCategory = (id: string) => {
  categoryToDeleteId.value = id;
  isCategoryFormOpen.value = false; // Close the category form dialog
  isConfirmDeleteOpen.value = true;
};

const deleteCategoryConfirmed = async () => {
  if (!categoryToDeleteId.value) return;

  loading.value = true;
  try {
    const { error } = await supabase
      .from("categories")
      .delete()
      .eq("id", categoryToDeleteId.value);
    if (error) throw error;
    loading.value = false; // Set loading to false before closing dialog
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    categoryToDeleteId.value = null; // Clear the ID
    toast.success("Kategori berhasil dihapus!", {
      description: "Kategori telah berhasil dihapus dari daftar.",
    });
    await fetchCategories();
  } catch (error: any) {
    toast.error("Gagal menghapus kategori!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
  isEditing.value = false;
  categoryForm.value = {
    id: "",
    name: "",
    description: "",
    is_active: true,
  };
};

onMounted(async () => {
  pageLoading.value = true; // Start loading state
  try {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCategories();
    }
  } catch (error: any) {
    toast.error("Terjadi kesalahan saat memuat data awal!", {
      description: error.message,
    });
  } finally {
    pageLoading.value = false; // End loading state
  }
});

watch(user, async (newUser) => {
  if (newUser) {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCategories();
    }
  } else {
    hasAdminOrManagerRole.value = false;
    categories.value = [];
  }
});
const formatDate = (dateString: string) => {
  const options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  };
  return new Date(dateString).toLocaleDateString("id-ID", options);
};
</script>

<style scoped>
.spinner {
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-left-color: #3b82f6; /* Blue-500 */
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
