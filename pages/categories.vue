<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
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
          <DialogContent class="sm:max-w-[600px] p-6">
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
                <Checkbox id="isActive" v-model:checked="categoryForm.is_active" />
                <Label for="isActive">Aktif</Label>
              </div>
              <div v-if="errorMessage" class="text-red-500 text-sm mt-4">
                {{ errorMessage }}
              </div>
              <div v-if="successMessage" class="text-green-500 text-sm mt-4">
                {{ successMessage }}
              </div>
              <DialogFooter>
                <Button type="submit" :disabled="loading">
                  <span v-if="loading">Menyimpan...</span>
                  <span v-else>{{
                    isEditing ? "Perbarui Kategori" : "Tambah Kategori"
                  }}</span>
                </Button>
                <DialogClose as-child>
                  <Button type="button" variant="outline" @click="cancelEdit"
                    >Batal</Button
                  >
                </DialogClose>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <!-- Daftar Kategori -->
      <div class="bg-white dark:bg-gray-800 shadow-md rounded-lg p-6">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Daftar Kategori
        </h2>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead class="min-w-[150px]">Nama</TableHead>
              <TableHead class="min-w-[200px]">Deskripsi</TableHead>
              <TableHead class="min-w-[80px]">Aktif</TableHead>
              <TableHead class="min-w-[150px]">Dibuat Pada</TableHead>
              <TableHead class="min-w-[150px]">Diperbarui Pada</TableHead>
              <TableHead class="min-w-[150px]">Aksi</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="category in categories" :key="category.id">
              <TableCell>{{ category.name }}</TableCell>
              <TableCell>{{ category.description }}</TableCell>
              <TableCell>{{ category.is_active ? "Ya" : "Tidak" }}</TableCell>
              <TableCell>{{ formatDate(category.created_at) }}</TableCell>
              <TableCell>{{ formatDate(category.updated_at) }}</TableCell>
              <TableCell>
                <Button
                  variant="outline"
                  size="sm"
                  @click="editCategory(category)"
                  class="mr-2"
                  >Edit</Button
                >
                <Button
                  variant="destructive"
                  size="sm"
                  @click="confirmDeleteCategory(category.id)"
                  >Hapus</Button
                >
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
        <div
          v-if="categories.length === 0 && !loading"
          class="text-center text-gray-500 dark:text-gray-400 mt-4"
        >
          Tidak ada kategori ditemukan.
        </div>
      </div>

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
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Categories - Aplikasi Kasir'
})
import { ref, onMounted } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
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
const errorMessage = ref("");
const successMessage = ref("");
const hasAdminOrManagerRole = ref(false);
const isCategoryFormOpen = ref(false); // Controls the add/edit category dialog
const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog
const categoryToDeleteId = ref<string | null>(null); // Stores the ID of the category to be deleted

const fetchCategories = async () => {
  loading.value = true;
  errorMessage.value = "";
  try {
    const { data, error } = await supabase
      .from("categories")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;
    categories.value = data as Category[];
  } catch (error: any) {
    errorMessage.value = error.message;
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
    console.error("Error fetching user role:", error.message);
    hasAdminOrManagerRole.value = false;
    return;
  }
  hasAdminOrManagerRole.value = data.role === "admin" || data.role === "manager";
  if (!hasAdminOrManagerRole.value) {
    errorMessage.value = "Anda tidak memiliki izin untuk mengakses halaman ini.";
  }
};

const saveCategory = async () => {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
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
      successMessage.value = "Kategori berhasil diperbarui!";
    } else {
      const { error } = await supabase.from("categories").insert({
        name: categoryForm.value.name,
        description: categoryForm.value.description,
        is_active: categoryForm.value.is_active,
      });
      if (error) throw error;
      successMessage.value = "Kategori berhasil ditambahkan!";
    }
    resetForm();
    await fetchCategories();
  } catch (error: any) {
    errorMessage.value = error.message;
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
  errorMessage.value = "";
  successMessage.value = "";
  isCategoryFormOpen.value = true; // Open the dialog for editing
};

const cancelEdit = () => {
  resetForm();
  isCategoryFormOpen.value = false; // Close the dialog on cancel
};

const confirmDeleteCategory = (id: string) => {
  categoryToDeleteId.value = id;
  isConfirmDeleteOpen.value = true;
};

const deleteCategoryConfirmed = async () => {
  if (!categoryToDeleteId.value) return;

  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    const { error } = await supabase
      .from("categories")
      .delete()
      .eq("id", categoryToDeleteId.value);
    if (error) throw error;
    successMessage.value = "Kategori berhasil dihapus!";
    await fetchCategories();
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    categoryToDeleteId.value = null; // Clear the ID
  } catch (error: any) {
    errorMessage.value = error.message;
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
  pageLoading.value = true; // Start loading
  try {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCategories();
    }
  } finally {
    pageLoading.value = false; // End loading
  }
});

watch(user, async (newUser) => {
  if (newUser) {
    // No need to set pageLoading here, as this watch is for reactive changes after initial load
    // The initial load is handled by onMounted
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
